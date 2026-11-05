import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.UserProfile;
import Toybox.Weather;

module CompanionDates {
    function key(moment) {
        var d = Gregorian.info(moment, Time.FORMAT_SHORT);
        return d.year * 10000 + d.month * 100 + d.day;
    }

    function sundayKey(now) {
        var d = Gregorian.info(new Time.Moment(now), Time.FORMAT_SHORT);
        // Sample local midday before subtracting days, avoiding DST midnight drift.
        var noon = Time.today().value() + 12 * 3600;
        return key(new Time.Moment(noon - (d.day_of_week - 1) * 86400));
    }
}

class CompanionData {
    var steps = null;
    var stepGoal = null;
    var runKm = null;
    var high = null;
    var low = null;
    var condition = null;
    var observation = 0;
    var lastHistoryMs = 0;
    private var lastFast = 0;
    private var lastHistory = 0;
    private var lastWeather = 0;
    private var lastDate = 0;
    private var previousSteps = null;
    private var previousStepsTime = 0;
    private var runId;
    private var nativeRunKm = null;
    private var sundaySetting = false;
    private var historyIterator;
    private var scanCount = 0;
    private var scanMeters = 0.0;
    private var scanSunday = 0;
    private var scanDate = 0;
    private var scanNow = 0;
    private var scanStart = 0;
    private var scanEnd = 0;
    private var scanSport = 0;

    function initialize() {
        runId = new Complications.Id(Complications.COMPLICATION_TYPE_WEEKLY_RUN_DISTANCE);
        try {
            var settings = System.getDeviceSettings();
            sundaySetting = settings.firstDayOfWeek == 1;
        } catch (e) { sundaySetting = false; }
    }

    function invalidate() as Void { lastFast = 0; }

    function refreshFast(model, now, dateKey) as Void {
        if (lastDate != dateKey) {
            lastDate = dateKey; previousSteps = null; previousStepsTime = 0;
            runKm = null; nativeRunKm = null; high = null; low = null; condition = null;
            lastFast = 0; lastHistory = 0; lastWeather = 0;
            historyIterator = null;
        }
        model.rollover(dateKey);
        if (lastFast > 0 && now >= lastFast && now - lastFast < 30) { return; }
        lastFast = now;
        try {
            var info = ActivityMonitor.getInfo();
            steps = info.steps; stepGoal = info.stepGoal;
        } catch (e) { steps = null; stepGoal = null; }
        model.observeSteps(steps, stepGoal);
        if (steps != null) {
            if (previousSteps == null || steps < previousSteps || now < previousStepsTime || now - previousStepsTime > 600) {
                previousSteps = steps; previousStepsTime = now;
            } else if (steps - previousSteps >= 120) {
                model.observeMovement(steps - previousSteps, now - previousStepsTime, now);
                previousSteps = steps; previousStepsTime = now;
            }
        }
        try {
            var value = Complications.getComplication(runId).value;
            if ((value instanceof Lang.Float || value instanceof Lang.Number) && value >= 0 && sundaySetting) {
                nativeRunKm = value / 1000.0; runKm = nativeRunKm;
            } else { nativeRunKm = null; }
        } catch (e) { nativeRunKm = null; }
    }

    // Called only after the first screen has painted, never from the renderer.
    function refreshSlow(model, now, dateKey) as Void {
        if (lastWeather == 0 || now < lastWeather || now - lastWeather >= 900) {
            lastWeather = now; readWeather(now, dateKey);
        }
        if (historyIterator == null && (lastHistory == 0 || now < lastHistory || now - lastHistory >= 300)) {
            lastHistory = now; startHistory(now, dateKey);
        }
        advanceHistory(model);
    }

    function sceneCondition(now) {
        if (observation <= 0 || now < observation || now - observation > 7200) { return null; }
        return condition;
    }

    private function readWeather(now, dateKey) as Void {
        high = null; low = null; condition = null; observation = 0;
        try {
            var forecasts = Weather.getDailyForecast();
            if (forecasts != null) {
                for (var i = 0; i < forecasts.size(); i += 1) {
                    var f = forecasts[i];
                    if (f.forecastTime != null && CompanionDates.key(f.forecastTime) == dateKey) {
                        high = f.highTemperature; low = f.lowTemperature; break;
                    }
                }
            }
            var c = Weather.getCurrentConditions();
            if (c != null && c.observationTime != null) {
                observation = c.observationTime.value();
                if (CompanionDates.key(c.observationTime) == dateKey) {
                    condition = c.condition;
                    if (high == null) { high = c.highTemperature; }
                    if (low == null) { low = c.lowTemperature; }
                }
            }
        } catch (e) {
            System.println("Weather unavailable; keeping neutral scene");
        }
    }

    private function startHistory(now, dateKey) as Void {
        try {
            historyIterator = UserProfile.getUserActivityHistory();
            scanCount = 0; scanMeters = 0.0; scanStart = 0; scanEnd = 0; scanSport = 0;
            scanSunday = CompanionDates.sundayKey(now); scanDate = dateKey; scanNow = now;
            lastHistoryMs = 0;
        } catch (e) { historyIterator = null; }
    }

    function advanceHistory(model) as Void {
        if (historyIterator == null) { return; }
        var began = System.getTimer();
        try {
            // At most 16 records / about 12ms of work per callback. Continue on
            // later wake callbacks; never keep the face awake just to finish.
            var batch = 0;
            while (batch < 16 && System.getTimer() - began < 12) {
                var record = historyIterator.next();
                if (record == null || scanCount >= 256) {
                    var complete = record == null;
                    historyIterator = null;
                    if (nativeRunKm == null) { runKm = complete ? scanMeters / 1000.0 : null; }
                    if (scanStart > 0) { model.observeWorkout(scanStart, scanEnd, scanSport, scanNow); }
                    model.finishHistorySeed();
                    lastHistoryMs += System.getTimer() - began;
                    System.println("History scan total ms: " + lastHistoryMs + "; complete: " + complete);
                    return;
                }
                scanCount += 1; batch += 1;
                var start = record.startTime;
                if (start != null && start.value() <= scanNow) {
                    var recordDay = CompanionDates.key(start);
                    if (record.type == Activity.SPORT_RUNNING && recordDay >= scanSunday &&
                        recordDay <= scanDate && record.distance != null && record.distance >= 0) {
                        scanMeters += record.distance;
                    }
                    if (recordDay == scanDate && record.duration != null) {
                        var end = start.value() + record.duration.value();
                        var sport = record.type == Activity.SPORT_RUNNING ? 1 :
                            (record.type == Activity.SPORT_TRAINING ? 2 : 0);
                        if (sport != 0 && start.value() > scanStart && end >= start.value() && end <= scanNow) {
                            scanStart = start.value(); scanEnd = end; scanSport = sport;
                        }
                    }
                }
            }
        } catch (e) {
            // Failed scans do not seed history or erase acknowledged events.
            historyIterator = null;
            System.println("Activity history unavailable");
        }
        lastHistoryMs += System.getTimer() - began;
    }
}
