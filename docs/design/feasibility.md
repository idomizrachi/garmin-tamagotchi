# v0.1 feasibility review

Reviewed 2026-11-05 against Garmin's public documentation. This is an API and device-specification review, not a simulator or hardware test.

## Result

The accepted watch-face composition and daily companion cycle are feasible in principle. Keep running-specific responses and interpret the broad Training sport as strength under the personal convention below. Exact strength-subtype recognition remains unproven. Prioritize native weekly distance over repeated history scans, subject to checking its week boundary.

## Primary device and graphics budget

Garmin lists `fr57047mm` with a round 454 × 454 display, 65,536 colors, and a watch-face memory limit of 131,072 bytes (128 KiB). Device storage capacity is not the application's memory budget. [Device reference](https://developer.garmin.com/connect-iq/device-reference/fr57047mm/)

Implementation recommendation: use small palette-based sprite resources, built-in fonts where suitable, and simple drawn time, icons, and ground line. Load only the poses needed for the current scene. Avoid full-screen frame sequences or full-screen off-screen buffers: a naive 454 × 454 × 2-byte buffer alone would occupy 412,232 bytes, before runtime overhead. Actual bitmap resource accounting must be measured with the SDK.

## Data sources and limits

| Requirement | Documented route | Assessment |
| --- | --- | --- |
| Weekly running kilometres | `Complications.COMPLICATION_TYPE_WEEKLY_RUN_DISTANCE`, expressed in metres | Best first candidate; verify availability and Sunday reset on device |
| Daily steps and goal | `ActivityMonitor.getInfo().steps` and `.stepGoal` | Supported API route; values require null checks |
| Weather high/low in Celsius | `Weather.getDailyForecast()` with matching forecast date | Supported API route; data may be absent |
| Weather scene | Cached current condition and observation timestamp | Supported; stale conditions must not be presented as current |
| Recent recorded run | `UserProfile.getUserActivityHistory()` | Broad sport, start, duration, and distance are documented |
| Strength-specific recovery | Saved history does not expose subtype | Cannot reliably distinguish strength from other training using this history alone |
| Daily continuity | `Application.Storage` | Supported; persist small event records rather than every frame |

The 570 is listed as supporting Complications. Native weekly running distance can be queried and subscribed to; a built-in type is not a guarantee that a value will always be available. Its documentation does not specify the week boundary or completeness of synced activities. Validate against the wearer's existing native value and Sunday–Saturday expectation before relying on it. Do not infer that an increase necessarily identifies a newly completed workout. [Complications API](https://developer.garmin.com/connect-iq/api-docs/Toybox/Complications.html)

ActivityMonitor provides steps since local midnight and a step goal. Compare valid samples to recognize movement bursts; handle midnight, missing samples, and count corrections before interpreting a delta as movement. This is an occasional response to accumulated movement, not a live walking detector. [ActivityMonitor.Info](https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityMonitor/Info.html)

Daily forecast entries expose a forecast timestamp and nullable high/low Celsius values. Select today's valid entry rather than blindly using the first result. [DailyForecast](https://developer.garmin.com/connect-iq/api-docs/Toybox/Weather/DailyForecast.html) Current conditions are cached and include an observation timestamp; their high/low values are another candidate when the observation belongs to today. [CurrentConditions](https://developer.garmin.com/connect-iq/api-docs/Toybox/Weather/CurrentConditions.html) The weather methods can return null. [Weather API](https://developer.garmin.com/connect-iq/api-docs/Toybox/Weather.html)

Recommended missing-data policy: render unavailable temperature components as `—`, omit weather scenery when conditions are missing or stale, and never silently carry yesterday's high/low into today. An initial two-hour freshness threshold for scene conditions is a proposed product choice, not a Garmin guarantee. Reading Garmin's cached weather avoids a separate weather service and API key; it does not guarantee fresh weather while disconnected.

## Workout responses

Saved `UserActivity` records expose `type`, `startTime`, `duration`, and `distance`, all nullable; no subtype is documented. [UserActivity](https://developer.garmin.com/connect-iq/api-docs/Toybox/UserProfile/UserActivity.html) Garmin defines strength as a subtype, while the training sport also encompasses cardio. Therefore treating every training record as strength would guess incorrectly. [Sport definitions](https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityRecording.html)

`UserProfile.getCurrentSport2()` exposes a current sport/subsport pair on newer APIs, but its presence does not prove that the subtype of a finished workout remains available after returning to the face. Keep it as a device probe, not a promised solution. [UserProfile](https://developer.garmin.com/connect-iq/api-docs/Toybox/UserProfile.html)

Personal-use convention, following the wearer's clarification that 99.9% of workouts are running and strength: map a valid new `SPORT_RUNNING` record to running celebration/recovery and a valid new `SPORT_TRAINING` record to strength celebration/recovery. This intentionally interprets a broad training category using the wearer's habits; it does not detect the strength subtype. A rare cardio or other session classified as Training will receive the strength response too. Missing, invalid, or other unrecognized sport records leave the ordinary routine in place. Verify that actual strength sessions on the watch produce the expected Training category. No extra app or manual action is required for the baseline.

Use valid start plus duration to estimate the end of a saved workout and anchor the 30–60-minute recovery window there. Reconcile dates and identify unseen records without replaying historic workouts on initial installation. Persist acknowledgment state across reloads. A delayed celebration is separate from physical recovery. The history API does not guarantee full Garmin Connect history, retention, ordering, or refresh latency in the reviewed reference; measure these rather than assuming them.

Avoid scanning history during each draw or animation frame. Read cached display data first, then refresh history at a bounded cadence and relevant returns to the face; measure execution cost before choosing the cadence. If a scan cannot establish a correct weekly total, do not label a partial sum as complete.

## Wake-time animation and always-on

The documented watch-face lifecycle enables timers and animations during a short high-power period after a wake gesture or return from another app, typically about ten seconds. Low-power mode disallows those animations and ordinarily updates once per minute. Recommend brief low-frame-count gestures and a settled pose; stop animation immediately on sleep entry. A wake callback is an opportunity for acknowledgment, not proof of attention. [WatchFace lifecycle](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/WatchFace.html)

AMOLED always-on updates are limited to once per minute and 10% of display pixels. Dim filled graphics still occupy pixels: darkness alone does not establish compliance. Use thin time glyphs and a much smaller sparse resting sprite, measure lit pixels, and verify device-specific protection behavior. The generated always-on mockup illustrates composition only. [Watch-face guidelines](https://developer.garmin.com/connect-iq/articles/user-experience-guidelines/Watch_Faces.html)

The watch face is the home screen, not an overlay on workout screens. Live workout APIs and direct sensor sampling are restricted for this app type; companion training responses primarily appear when the wearer returns to the face. [App types and API access](https://developer.garmin.com/connect-iq/articles/connect-iq-basics/App_Types.html)

## Continuity and scheduling

Persistent small records can retain the local date, acknowledged workout identifiers, step-goal celebration state, and current scene seed. Write on meaningful changes rather than every draw. [Application.Storage](https://developer.garmin.com/connect-iq/api-docs/Toybox/Application/Storage.html)

Derive the current routine from local time whenever shown; do not require code to run at precisely 07:00 or bedtime. Handle date changes, travel, and clock adjustments. Do not try to override the wearer's sleep-focus display choice. Never confuse the watch-face low-power lifecycle with the companion's fictional sleep schedule.

## Validation still needed

### Existing local reference: Mini Me V2

Inspected `/Users/idomizrachi/personal-dev/garmin-mini-me-v2/source` after the wearer identified it as related work. Its README reports a verified primary-device build; this review did not rebuild or run it. It provides implementation precedent, not proof of accurate on-watch data or battery use.

- `MiniMeV2WatchFaceView.mc:329–383` caches weekly distance for 60 minutes, iterates saved activity history, selects `Activity.SPORT_RUNNING`, and sums metres. This directly demonstrates the intended use of the saved sport category in existing local code. It does not classify strength.
- `:423–460` derives week start from device settings, defaulting to Sunday. The new project requires Sunday explicitly. Existing code scans all history and subtracts fixed 24-hour days; review execution cost and daylight-saving boundaries before reuse. Its cache also needs week-boundary and clock-change invalidation.
- `:385–421` reads current temperature with a 15-minute cache, not the chosen high/low forecast. It retains old temperature on missing data without a freshness check, and unsuccessful initial reads are retried on each draw. Adapt rather than copy unchanged.
- `:312–326` reads steps with null/exception handling, but missing data becomes zero. Distinguish unavailable data from genuine zero in the new project.
- `:192–237` lazy-loads day, celebration, and sleep images; loaded images remain referenced. Measure retained memory rather than assuming lazy loading bounds total use.
- `:291–293` uses a fixed 10,000-step threshold and continuously shows the celebration state afterward. The new project uses the watch's daily goal and bounded celebrations with persistent acknowledgment.
- `:502–505` defines sleep as 21:30–06:00. Replace with the agreed 07:00 waking, 20:30 sleepiness, and 22:30–23:00 bedtime progression.
- Both `onUpdate` and `onPartialUpdate` redraw the full face; there is no dedicated low-power view or wake/sleep animation handling. Implement the agreed sparse always-on mode independently.
- Existing Day Journey moves the character hourly along a lane with start/finish markers. That belongs to the other project's glossary; this project instead keeps a fixed minimal stage without markers.

The other repository was inspected read-only; its character, terminology, schedule, and layout were not adopted automatically.

No application source or build configuration exists yet. `monkeyc` and `connectiq` were not found on PATH; the standard user Garmin ConnectIQ directory was absent. No build, simulator run, memory profile, or on-watch measurement was performed.

1. Install/locate the SDK and primary device package; compile a minimal diagnostic face.
2. Check native running complication against the wearer's total, Sunday rollover, and missing-value behavior.
3. Inspect saved run and strength records and current-sport behavior after returning from each workout. Measure history query cost.
4. Exercise missing/stale weather and local date transitions.
5. Render the accepted layout at 454 × 454; verify number widths, clipping, expressions, and AOD pixel budget.
6. Measure memory, wake responsiveness, and animation timing in the simulator and on the watch.
7. Compare battery drain over matched multi-day usage with equal AOD, brightness, and workout settings before making any battery-life claim.

Expansion candidates: Forerunner 970 and 965 share the 454 × 454 round AMOLED geometry; Forerunner 570 42 mm provides a 390 × 390 layout test. These are candidates, not verified supported targets. [Compatible devices](https://developer.garmin.com/connect-iq/compatible-devices/)
