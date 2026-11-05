# v0.1 validation

Validated on 2026-11-05 with Connect IQ SDK 9.3.0 and simulator device API 6.0.3.

## Completed

- Release builds succeed for `fr57047mm`, `fr57042mm`, `fr965`, and `fr970`.
- All ten behavior tests pass in the Forerunner 570 47 mm simulator. The test
  runner is wrapped so its nonstandard success exit status is interpreted using
  the explicit final result, rather than hiding failures.
- Active layouts were visually inspected on the 454 × 454 and 390 × 390
  Forerunner 570 simulators. The final date is above the bold clock; the clock's
  center position is unchanged. Fields follow the lower circular edge.
- The approved companion is represented by twelve compact pixel-art poses.
- The lightweight grass, pebbles, and stepped ridges render without any added
  background bitmap or buffer. They are omitted from always-on mode.
- Always-on was exercised in the 47 mm simulator. Its exported 454 × 454 frame
  lights 0.767044% of pixels, measured by counting any nonblack RGB pixel. This
  is one representative time, not an exhaustive test of all clock strings.
- Application-memory samples shown by the simulator were approximately 19.8 KB
  after the environment and vector fonts were added, against the displayed
  123.8 KB usable limit. This is a sample, not a peak-memory guarantee.
- The simulator supplied weather high/low values, with no runtime errors observed.
- History refresh uses batches of at most 16 records and checks a roughly 12 ms
  callback budget between records. It resumes on subsequent wake callbacks;
  it does not extend wake time to finish a scan. A single API call can still
  exceed the soft budget on actual firmware.

## Behavior tests

1. Late workout wind-down is bounded and yields to sleep.
2. A missed workout is acknowledged without restarting physical recovery.
3. Initial installation seeds old workouts without replaying celebrations.
4. Persistence prevents a repeated workout from resetting its celebration count.
5. Missing steps do not trigger a goal, and the daily goal resets with the date.
6. Nighttime glances do not spend pending celebrations.
7. Ordinary movement does not delay bedtime; stale movement samples are ignored.
8. Unknown, future-ended, or invalid workouts do not trigger a response.
9. A held prop and lingering prop are not duplicated.
10. Invalid schedule ordering and corrupt storage are ignored safely.

## Remaining on-watch checks

- Confirm a real Running record and Training record match the personal mapping.
- Compare the running total with the native face, including a Sunday rollover.
- Check history retention, sync completeness, pause-duration effects on estimated
  workout end time, and scan latency with a large activity history.
- Check reconnects, missing forecasts, stale conditions, timezone changes, and
  overnight rollover using real watch data.
- Assess readability on the wrist in daylight and always-on mode.
- Measure actual peak memory, wake responsiveness, and multi-day battery drain
  with comparable brightness, AOD, and workout use.

No hardware battery-life result, actual recorded-workout verification, or public
Connect IQ release is claimed. The 965 and 970 have build validation only.

## Captures

- `simulator-active.png`: lightweight environment and revised fonts, captured
  before the final move of the date above the clock.
- `simulator-always-on.png`: sparse low-power rendering used for the pixel count.

Both use simulator-provided sample data rather than the wearer's actual readings.
