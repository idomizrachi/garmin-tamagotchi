import Toybox.Lang;

// Pure behavior model. Time, activity and persistence are supplied by the caller.
// No API reads, rendering, timers or storage access belong here.
class CompanionModel {
    const IDLE = 0;
    const BLINK = 1;
    const WAVE = 2;
    const STRETCH = 3;
    const COFFEE = 4;
    const SIP = 5;
    const WALK = 6;
    const RUN = 7;
    const STRENGTH = 8;
    const CELEBRATE = 9;
    const WATER = 10;
    const SLEEP = 11;

    var day = 0;
    var workoutStart = 0;
    var workoutEnd = 0;
    var workoutSport = 0;
    var workoutCheers = 0;
    var stepCheers = 0;
    var goalSeen = false;
    var historySeeded = false;
    var lastWake = 0;
    var movementUntil = 0;
    var lastMovement = 0;
    var prop = 0; // 0 none, 1 mug, 2 bottle
    var propUntil = 0;
    var wakeMinute = 420;
    var sleepyMinute = 1230;
    var bedMinute = 1365;
    var dirty = false;
    var wakePose = 0;

    function initialize() {}

    function setSchedule(wake, sleepy, bed) as Void {
        // v0.1 supports the agreed same-day daytime schedule.
        if (wake >= 0 && wake < sleepy && sleepy < bed && bed < 1440) {
            wakeMinute = wake; sleepyMinute = sleepy; bedMinute = bed;
        }
    }

    function rollover(dateKey) as Void {
        if (day == dateKey) { return; }
        day = dateKey;
        workoutStart = 0; workoutEnd = 0; workoutSport = 0;
        workoutCheers = 0; stepCheers = 0; goalSeen = false;
        movementUntil = 0; lastMovement = 0; prop = 0; propUntil = 0;
        lastWake = 0; wakePose = IDLE; dirty = true;
        // Keep historySeeded across dates: old history must not replay on reload.
    }

    function observeSteps(steps, goal) as Void {
        if (steps == null || goal == null || goal <= 0) { return; }
        if (!goalSeen && steps >= goal) {
            goalSeen = true; stepCheers = 3; dirty = true;
        }
    }

    function observeMovement(delta, elapsed, now) as Void {
        if (elapsed > 0 && elapsed <= 600 && delta >= 120 && now - lastMovement >= 900) {
            movementUntil = now + 180; lastMovement = now;
        }
    }

    function observeWorkout(start, end, sport, now) as Void {
        if (start <= 0 || end < start || end > now || start <= workoutStart) { return; }
        // Caller supplies only today's valid records, classified 1 run / 2 strength.
        if (sport != 1 && sport != 2) { return; }
        workoutStart = start; workoutEnd = end; workoutSport = sport;
        if (historySeeded) { workoutCheers = 3; }
        dirty = true;
    }

    function finishHistorySeed() as Void {
        if (!historySeeded) { historySeeded = true; dirty = true; }
    }

    function isNight(minute, now) {
        if (minute < wakeMinute) { return true; }
        if (minute < bedMinute) { return false; }
        // Late exercise gets a bounded wind-down; ordinary movement cannot delay sleep.
        return !(workoutEnd > 0 && now >= workoutEnd && now - workoutEnd < 1800 && minute < bedMinute + 30);
    }

    function beginGlance(now, minute) as Void {
        // Repeated lifecycle callbacks within one glance do not spend celebrations.
        if (lastWake > 0 && now - lastWake >= 0 && now - lastWake < 45) { return; }
        lastWake = now; wakePose = IDLE;
        if (isNight(minute, now)) { return; }
        if (workoutCheers > 0) {
            wakePose = CELEBRATE; workoutCheers -= 1; dirty = true;
        } else if (stepCheers > 0) {
            wakePose = CELEBRATE; stepCheers -= 1; dirty = true;
        } else if (((now / 60).toNumber() + day) % 9 == 0) {
            wakePose = WAVE;
        }
    }

    function pose(now, minute, frame, active) {
        if (isNight(minute, now)) { return SLEEP; }
        if (active && now - lastWake >= 0 && now - lastWake < 4 && wakePose != IDLE) {
            return wakePose;
        }
        if (workoutEnd > 0 && now >= workoutEnd && now - workoutEnd < 2700) {
            var recoverySlot = ((now / 180).toNumber() + day) % 4;
            if (recoverySlot == 0) { return STRETCH; }
            if (recoverySlot == 1) { return workoutSport == 1 ? RUN : STRENGTH; }
            return WATER;
        }
        if (minute >= sleepyMinute) { return STRETCH; } // yawn/stretch sprite
        if (minute < wakeMinute + 20) { return STRETCH; }
        if (now < movementUntil) { return WALK; }
        var slot = ((now / 300).toNumber() + day) % 8;
        if (minute >= wakeMinute + 20 && minute < 690 && slot < 5) {
            if (prop != 1 || propUntil < now) { dirty = true; }
            prop = 1; propUntil = now + 1200;
            return active && frame == 2 ? SIP : COFFEE;
        }
        if (slot == 2) { return STRETCH; }
        if (active && frame == 1) { return BLINK; }
        return IDLE;
    }

    function currentProp(now, poseId) {
        // A held prop and a lingering prop never appear simultaneously.
        if (poseId == COFFEE || poseId == SIP || poseId == WATER || poseId == SLEEP || poseId == STRENGTH) { return 0; }
        if (workoutEnd > 0 && now >= workoutEnd && now - workoutEnd < 3600) { return 2; }
        if (now < propUntil) { return prop; }
        return 0;
    }

    function snapshot() {
        return { "day" => day, "start" => workoutStart, "end" => workoutEnd,
            "sport" => workoutSport, "cheers" => workoutCheers, "steps" => stepCheers,
            "goal" => goalSeen, "seed" => historySeeded, "prop" => prop, "propUntil" => propUntil };
    }

    function restore(state) as Void {
        if (!(state instanceof Lang.Dictionary)) { return; }
        if (!(state.hasKey("day") && state.hasKey("seed") && state.hasKey("goal") &&
            state.hasKey("start") && state.hasKey("end") && state.hasKey("sport") &&
            state.hasKey("cheers") && state.hasKey("steps"))) { return; }
        if (!(state["day"] instanceof Lang.Number && state["start"] instanceof Lang.Number &&
            state["end"] instanceof Lang.Number && state["sport"] instanceof Lang.Number &&
            state["cheers"] instanceof Lang.Number && state["steps"] instanceof Lang.Number &&
            state["seed"] instanceof Lang.Boolean && state["goal"] instanceof Lang.Boolean)) { return; }
        day = state["day"]; workoutStart = state["start"]; workoutEnd = state["end"];
        workoutSport = state["sport"]; workoutCheers = state["cheers"];
        stepCheers = state["steps"]; goalSeen = state["goal"]; historySeeded = state["seed"];
        if (state.hasKey("prop") && state.hasKey("propUntil") &&
            state["prop"] instanceof Lang.Number && state["propUntil"] instanceof Lang.Number) {
            prop = state["prop"]; propUntil = state["propUntil"];
        }
    }
}
