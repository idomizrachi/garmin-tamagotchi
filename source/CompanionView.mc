import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Timer;
import Toybox.WatchUi;

class CompanionView extends WatchUi.WatchFace {
    private var model;
    private var data;
    private var renderer;
    private var active = true;
    private var timer;
    private var frame = 0;
    private var pendingGlance = true;
    private var lastSlowRefresh = 0;

    function initialize() {
        WatchFace.initialize();
        model = new CompanionModel(); data = new CompanionData(); renderer = new CompanionRenderer();
        timer = new Timer.Timer();
        try { model.restore(Application.Storage.getValue("daily-v1")); } catch (e) {}
        settingsChanged();
    }

    function settingsChanged() as Void {
        try {
            model.setSchedule(Application.Properties.getValue("WakeMinute"),
                Application.Properties.getValue("SleepyMinute"), Application.Properties.getValue("BedMinute"));
        } catch (e) {}
    }

    function onShow() as Void { wake(); }
    function onExitSleep() as Void { wake(); }

    private function wake() as Void {
        active = true; frame = 0; pendingGlance = true;
        data.invalidate();
        timer.stop();
        // A deferred callback lets the clock paint before querying workout history.
        timer.start(method(:advance), 600, true);
        WatchUi.requestUpdate();
    }

    function onEnterSleep() as Void {
        active = false; timer.stop(); frame = 0; renderer.release(); save();
        WatchUi.requestUpdate();
    }

    function onHide() as Void { timer.stop(); renderer.release(); save(); }

    function advance() as Void {
        frame += 1;
        var now = Time.now().value();
        if (frame == 1 && (lastSlowRefresh == 0 || now < lastSlowRefresh || now - lastSlowRefresh >= 30)) {
            lastSlowRefresh = now;
            data.refreshSlow(model, now, CompanionDates.key(Time.now()));
        } else {
            data.advanceHistory(model);
        }
        // Newly discovered workouts can be acknowledged during this same glance.
        if (model.workoutCheers > 0 && model.wakePose != model.CELEBRATE) {
            model.lastWake = 0;
            var c = System.getClockTime(); model.beginGlance(now, c.hour * 60 + c.min);
        }
        save();
        if (frame >= 6) { timer.stop(); }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var now = Time.now(); var epoch = now.value(); var clock = System.getClockTime();
        var minute = clock.hour * 60 + clock.min;
        data.refreshFast(model, epoch, CompanionDates.key(now));
        if (pendingGlance) {
            model.beginGlance(epoch, minute); pendingGlance = false; save();
        }
        var pose = model.pose(epoch, minute, frame < 6 ? frame : 0, active);
        renderer.draw(dc, clock, Gregorian.info(now, Time.FORMAT_SHORT), model, data, pose, epoch, !active);
    }

    function save() as Void {
        if (!model.dirty) { return; }
        try { Application.Storage.setValue("daily-v1", model.snapshot()); model.dirty = false; }
        catch (e) { System.println("Daily state could not be saved"); }
    }
}
