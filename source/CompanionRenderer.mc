import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class CompanionRenderer {
    private var sprite;
    private var spriteId = -1;
    private var aod;
    private const WHITE = 0xEEF5F0;
    private const MUTED = 0xAABCB4;
    private const TEAL = 0x5EB8A9;
    private var scale = 1.0;
    private var fontWidth = 0;
    private var clockFont;
    private var dateFont;
    private var labelFont;
    private var valueFont;
    private var aodFont;

    function initialize() {}
    function release() as Void { sprite = null; spriteId = -1; }
    private function px(value) { return (value * scale).toNumber(); }

    function draw(dc, clock, date, model, data, pose, now, lowPower) as Void {
        scale = dc.getWidth() / 454.0;
        prepareFonts(dc.getWidth());
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK); dc.clear();
        var time = Lang.format("$1$:$2$", [clock.hour.format("%02d"), clock.min.format("%02d")]);
        if (lowPower) { drawAlwaysOn(dc, time, clock.min); return; }
        text(dc, 227, 91, clockFont, time, WHITE);
        var weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
        var months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
        var label = Lang.format("$1$ $2$ $3$", [weekdays[date.day_of_week - 1], date.day.format("%02d"), months[date.month - 1]]);
        text(dc, 227, 27, dateFont, label, MUTED);
        drawEnvironment(dc, clock.hour);
        drawCompanion(dc, pose);
        dc.setColor(0x395E56, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(px(155), px(324), px(144), px(2));
        drawProp(dc, model.currentProp(now, pose));
        drawWeatherScene(dc, data.sceneCondition(now), clock.hour);

        text(dc, 98, 311, valueFont, data.runKm == null ? "—" : data.runKm.format("%.1f"), WHITE);
        text(dc, 98, 343, labelFont, "km / week", MUTED);
        text(dc, 356, 311, valueFont, stepsText(data.steps), WHITE);
        text(dc, 356, 343, labelFont, "steps", MUTED);
        text(dc, 227, 374, labelFont, "HI / LO  °C", MUTED);
        var weather = temperature(data.high) + " / " + temperature(data.low);
        text(dc, 227, 408, valueFont, weather, WHITE);
        accent(dc, 98, 363, 48); accent(dc, 356, 363, 48); accent(dc, 227, 435, 56);
    }

    private function prepareFonts(width) as Void {
        if (fontWidth == width) { return; }
        fontWidth = width;
        clockFont = font("RobotoCondensedBold", 132, Graphics.FONT_NUMBER_HOT);
        dateFont = font("RobotoCondensedBold", 30, Graphics.FONT_XTINY);
        labelFont = font("RobotoCondensedBold", 26, Graphics.FONT_XTINY);
        valueFont = font("RobotoCondensedBold", 46, Graphics.FONT_SMALL);
        aodFont = font("RobotoCondensedRegular", 68, Graphics.FONT_XTINY);
    }

    private function font(face, size, fallback) {
        var result = Graphics.getVectorFont({:face => face, :size => px(size)});
        return result == null ? fallback : result;
    }

    private function drawCompanion(dc, pose) as Void {
        if (spriteId != pose || sprite == null) {
            release();
            var ids = [Rez.Drawables.Idle, Rez.Drawables.Blink, Rez.Drawables.Wave,
                Rez.Drawables.Stretch, Rez.Drawables.Coffee, Rez.Drawables.Sip,
                Rez.Drawables.Walk, Rez.Drawables.Run, Rez.Drawables.Strength,
                Rez.Drawables.Celebrate, Rez.Drawables.Water, Rez.Drawables.Sleep];
            sprite = WatchUi.loadResource(ids[pose]); spriteId = pose;
        }
        // Resources have size-specific overrides; no bitmap scaling at runtime.
        dc.drawBitmap((dc.getWidth() - sprite.getWidth()) / 2, px(324) - sprite.getHeight(), sprite);
    }

    private function drawEnvironment(dc, hour) as Void {
        // Sparse pixel scenery, not a full-screen bitmap or off-screen buffer.
        // Roughly twenty small primitives; no extra resource loads or timers.
        var night = hour >= 20 || hour < 7;
        dc.setColor(night ? 0x172722 : 0x233D34, Graphics.COLOR_TRANSPARENT);
        // Low stepped ridges frame the stage without crossing any data fields.
        dc.fillRectangle(px(122), px(277), px(20), px(3));
        dc.fillRectangle(px(130), px(273), px(13), px(4));
        dc.fillRectangle(px(137), px(269), px(9), px(4));
        dc.fillRectangle(px(307), px(272), px(20), px(3));
        dc.fillRectangle(px(307), px(266), px(11), px(6));
        dc.fillRectangle(px(310), px(262), px(5), px(4));
        dc.setColor(night ? 0x264438 : 0x426B52, Graphics.COLOR_TRANSPARENT);
        // Two little grass clumps beside the companion's permanent spot.
        dc.fillRectangle(px(153), px(309), px(3), px(14));
        dc.fillRectangle(px(148), px(313), px(3), px(7));
        dc.fillRectangle(px(151), px(317), px(9), px(6));
        dc.fillRectangle(px(158), px(311), px(3), px(8));
        dc.fillRectangle(px(292), px(314), px(3), px(9));
        dc.fillRectangle(px(288), px(311), px(3), px(7));
        dc.fillRectangle(px(290), px(319), px(9), px(4));
        // Muted pebbles connect the sparse ground line to the field arcs.
        dc.setColor(night ? 0x333C38 : 0x59635A, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(px(143), px(331), px(9), px(3));
        dc.fillRectangle(px(145), px(329), px(5), px(2));
        dc.fillRectangle(px(302), px(331), px(10), px(3));
        dc.fillRectangle(px(304), px(328), px(5), px(3));
        dc.setColor(night ? 0x20362D : 0x314E40, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(px(169), px(329), px(5), px(2));
        dc.fillRectangle(px(278), px(330), px(8), px(2));
    }

    private function drawAlwaysOn(dc, time, minute) as Void {
        // Conservative sparse mode: modest built-in font + tiny dim sprite.
        var shift = (minute % 3 - 1) * 3;
        text(dc, 227 + shift, 145 + shift, aodFont, time, 0x555D5B);
        if (aod == null) { aod = WatchUi.loadResource(Rez.Drawables.AodSleep); }
        dc.drawBitmap((dc.getWidth() - aod.getWidth()) / 2 + px(shift), px(285 + shift), aod);
    }

    private function text(dc, x, y, font, value, color) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(px(x), px(y), font, value, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function accent(dc, x, y, width) as Void {
        dc.setColor(TEAL, Graphics.COLOR_TRANSPARENT);
        // A shallow three-segment curve follows the lower circular face.
        dc.drawLine(px(x - width/2), px(y - 3), px(x - width/4), px(y));
        dc.drawLine(px(x - width/4), px(y), px(x + width/4), px(y));
        dc.drawLine(px(x + width/4), px(y), px(x + width/2), px(y - 3));
    }

    private function temperature(value) {
        return value == null ? "—" : value.format("%.0f") + "°";
    }

    private function stepsText(value) {
        if (value == null) { return "—"; }
        if (value < 1000) { return value.format("%d"); }
        if (value >= 10000) { return (value / 1000.0).format("%.1f") + "k"; }
        return (value / 1000).toNumber().format("%d") + "," + (value % 1000).format("%03d");
    }

    private function drawProp(dc, kind) as Void {
        if (kind == 0) { return; }
        dc.setColor(kind == 1 ? 0xD6A859 : 0x779AA0, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(px(290), px(kind == 1 ? 313 : 302), px(9), px(kind == 1 ? 10 : 21));
        if (kind == 1) {
            dc.drawRectangle(px(299), px(315), px(4), px(5));
        } else { dc.fillRectangle(px(292), px(298), px(5), px(4)); }
    }

    private function drawWeatherScene(dc, condition, hour) as Void {
        if (condition == null) { return; }
        dc.setColor(0xB29B60, Graphics.COLOR_TRANSPARENT);
        if (condition == 0) {
            if (hour >= 19 || hour < 7) {
                dc.fillCircle(px(301), px(189), px(9));
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(px(305), px(185), px(8));
            } else {
                dc.fillCircle(px(301), px(189), px(6));
                dc.drawLine(px(301), px(178), px(301), px(175));
                dc.drawLine(px(301), px(200), px(301), px(203));
                dc.drawLine(px(290), px(189), px(287), px(189));
                dc.drawLine(px(312), px(189), px(315), px(189));
            }
        } else {
            dc.setColor(0x6F8A87, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(px(294), px(190), px(5)); dc.fillCircle(px(302), px(187), px(7));
            dc.fillRectangle(px(294), px(190), px(17), px(5));
        }
    }
}
