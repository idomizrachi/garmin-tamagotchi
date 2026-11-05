import Toybox.Application;
import Toybox.Graphics;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// Documentation-only scenes using the real renderer and clearly synthetic data.
class PreviewApp extends Application.AppBase {
    function initialize() { AppBase.initialize(); }
    function getInitialView() { return [new PreviewView()]; }
}

class PreviewClock {
    var hour = 14;
    var min = 20;
    function initialize(pose) {
        if (pose == 4) { hour = 8; min = 15; }
        if (pose == 7 || pose == 8) { hour = 18; min = 40; }
        if (pose == 10) { hour = 18; min = 45; }
    }
}

class PreviewView extends WatchUi.WatchFace {
    private var renderer;
    private var model;
    private var data;
    private var pose = 0;
    function initialize() {
        WatchFace.initialize(); renderer = new CompanionRenderer();
        model = new CompanionModel(); data = new CompanionData();
        var configured = Application.Properties.getValue("PreviewPose");
        if (configured != null) { pose = configured; }
        data.steps = 6420; data.runKm = 24.6; data.high = 24; data.low = 17;
        data.condition = 0; data.observation = Time.now().value();
    }
    function onUpdate(dc as Graphics.Dc) as Void {
        var now = Time.now();
        renderer.draw(dc, new PreviewClock(pose), Gregorian.info(now, Time.FORMAT_SHORT),
            model, data, pose, now.value(), false);
    }
}
