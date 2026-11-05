# Simulator performance check

Tested 2026-11-05 with Connect IQ SDK 9.3.0, `fr57047mm`, simulator API 6.0.3,
and release optimization `-O 2p`. Measurements use `System.getTimer()` around
the production renderer, drawing to the simulator's actual display context.

## Result

The drawing workload looks suitable for the intended subtle gestures. This is
evidence for an expectation of responsive rendering, not a hardware or battery
guarantee. The physical watch is ready for a first sideload test.

| Check | Result |
| --- | --- |
| Normal cached draws | 360 samples; average 22.09 ms |
| First draw per pose, including the first font setup | 12 samples; worst 35 ms |
| Worst cached normal draw | 62 ms |
| Always-on cached draws | 30 samples; average 5.07 ms, worst 6 ms |
| Sprite-change stress | 240 changes; average 22.95 ms, worst 101 ms |
| Sampled application-memory peak | 23,232 bytes / 126,784 bytes (18.3%) |
| Memory at the end | 23,104 bytes used; 103,680 bytes free |
| Fast data read | 1 ms in this simulator fixture |
| Weather/history refresh | 0 ms at millisecond resolution; history was empty |
| Total renderer calls | 643 |
| Bounded run | Completed, `PERF_DONE`, no reported error |

Peak means the largest application-memory value sampled after draw calls. It
does not measure transient native/GPU allocation or establish an exhaustive
worst case. Simulator timing can include desktop scheduling, and must not be
treated as an on-watch frame-rate measurement.

## Workload

The isolated `bench/PerformanceApp.mc` entry point exercises the unchanged
`CompanionRenderer` using representative populated fields, weather scenery,
all twelve poses, and always-on mode. Each pose gets one first draw followed
by thirty cached draws. Ten later callbacks each perform twenty-four sprite
changes. Application memory is sampled after each draw.

The first stress attempt deliberately put all 240 changes in one callback and
hit Garmin's watchdog. That was an unrealistic benchmark design, not the
normal face's scheduling. The final test splits that work across bounded
callbacks; the application itself draws at system updates plus six brief
600 ms wake callbacks, then stops its gesture timer.

The source under `bench/` is outside the release build's source path and uses
separate application IDs. It does not add benchmark work to the normal face.
The benchmark's own memory overhead is included in its samples.

## Interpretation

An average draw of about 22 ms is a small part of the intended 600 ms gesture
interval. The companion is deliberately pose-based, so there is no requirement
to sustain continuous 60 fps animation. The observed 62–101 ms outliers mean
that an average alone would be insufficient evidence for that kind of animation.

The environment adds about twenty small pixel primitives. There is no full-screen
background bitmap or off-screen buffer, and only the current normal-size pose is
held by the renderer. This avoids the large background decoding and allocation
work that concerned the wearer in an earlier experiment.

## Main remaining risk: real data calls

The simulator history was empty. Therefore this test does not establish how fast
`getUserActivityHistory()`, iterator creation, or `next()` will be on the watch
with a real activity history. The 12 ms history-batch threshold is a soft limit
checked between calls; one slow native call can exceed it. Likewise, simulator
weather and complication reads are not proof of physical firmware latency.

## Physical-watch check

1. Install the normal `LittleCompanion-fr57047mm.prg`, not a benchmark or preview.
2. Compare wrist-raise response and menu navigation with the existing face.
3. Check a cold start, several glances, always-on, and wake from always-on.
4. Return after a recorded run and strength session; check acknowledgment,
   running totals, and whether the first return has a noticeable pause.
5. If these feel responsive, compare battery drain across one or two days with
   comparable brightness, AOD, and workout use. Do not infer battery life from
   render milliseconds alone.

Raw measurements: [per-scenario CSV](performance-fr57047mm.csv) and
[complete successful run](performance-fr57047mm.txt).

To reproduce, stop the previous simulator app via File → Kill App, then run
`python3 scripts/benchmark.py`. Use `--build-only` to compile without launching.
