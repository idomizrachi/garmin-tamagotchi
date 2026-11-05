import Toybox.Application;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Timer;
import Toybox.WatchUi;

// Separate simulator-only entry point. Not part of the release source path.
class PerformanceApp extends Application.AppBase {
    function initialize() { AppBase.initialize(); }
    function getInitialView() { return [new PerformanceView()]; }
}

class PerformanceView extends WatchUi.WatchFace {
    private var renderer;
    private var model;
    private var data;
    private var timer;
    private var stage = -1;
    private var drawn = -1;
    private var peak = 0;
    private var swapTotal = 0;
    private var swapMax = 0;

    function initialize() {
        WatchFace.initialize(); renderer = new CompanionRenderer();
        model = new CompanionModel(); data = new CompanionData(); timer = new Timer.Timer();
        data.steps = 6420; data.runKm = 24.6; data.high = 24; data.low = 17;
        data.condition = 0; data.observation = Time.now().value();
    }

    function onShow() as Void { timer.start(method(:nextStage), 400, true); }
    function onHide() as Void { timer.stop(); }
    function onEnterSleep() as Void { timer.stop(); }
    function nextStage() as Void {
        stage += 1;
        if (stage > 23) { timer.stop(); return; }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        if (stage < 0 || stage == drawn || stage > 23) { return; }
        drawn = stage;
        var now = Time.now().value(); var date = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var clock = System.getClockTime();
        if (stage <= 12) {
            renderer.release();
            var start = System.getTimer();
            renderer.draw(dc, clock, date, model, data, stage % 12, now, stage == 12);
            var first = System.getTimer() - start;
            var total = 0; var maximum = 0;
            var before = System.getSystemStats();
            if (before.usedMemory > peak) { peak = before.usedMemory; }
            for (var i = 0; i < 30; i += 1) {
                start = System.getTimer();
                renderer.draw(dc, clock, date, model, data, stage % 12, now, stage == 12);
                var elapsed = System.getTimer() - start;
                total += elapsed;
                if (elapsed > maximum) { maximum = elapsed; }
                var stats = System.getSystemStats();
                if (stats.usedMemory > peak) { peak = stats.usedMemory; }
            }
            System.println("PERF_RENDER," + stage + "," + first + "," + total + ",30," + maximum + "," + peak);
        } else if (stage <= 22) {
            var started = System.getTimer(); var maximumSwap = 0;
            for (var j = 0; j < 24; j += 1) {
                var began = System.getTimer();
                renderer.draw(dc, clock, date, model, data, j % 12, now, false);
                var swap = System.getTimer() - began;
                if (swap > maximumSwap) { maximumSwap = swap; }
                var memory = System.getSystemStats();
                if (memory.usedMemory > peak) { peak = memory.usedMemory; }
            }
            swapTotal += System.getTimer() - started;
            if (maximumSwap > swapMax) { swapMax = maximumSwap; }
            if (stage == 22) { System.println("PERF_SWAPS,240," + swapTotal + "," + swapMax + "," + peak); }
        } else {
            var beganFast = System.getTimer();
            data.refreshFast(model, now, CompanionDates.key(Time.now()));
            var fast = System.getTimer() - beganFast;
            var beganSlow = System.getTimer();
            data.refreshSlow(model, now, CompanionDates.key(Time.now()));
            var slow = System.getTimer() - beganSlow;
            var finalStats = System.getSystemStats();
            System.println("PERF_DATA," + fast + "," + slow + "," + data.lastHistoryMs);
            System.println("PERF_MEMORY," + finalStats.usedMemory + "," + finalStats.freeMemory + "," + finalStats.totalMemory + "," + peak);
            System.println("PERF_DONE"); timer.stop();
            System.exit();
        }
    }
}
