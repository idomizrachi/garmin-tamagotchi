import Toybox.Application;
import Toybox.WatchUi;

class CompanionApp extends Application.AppBase {
    private var face;

    function initialize() { AppBase.initialize(); }

    function getInitialView() {
        face = new CompanionView();
        return [face];
    }

    function onSettingsChanged() as Void {
        if (face != null) { face.settingsChanged(); }
        WatchUi.requestUpdate();
    }

    function onStop(state) as Void {
        if (face != null) { face.save(); }
    }
}
