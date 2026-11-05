#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
device="${1:-fr57047mm}"
./scripts/build.sh "$device" test
sdk="${CIQ_SDK:-}"
if [[ -z "$sdk" && -d .tools/sdk ]]; then sdk="$PWD/.tools/sdk"; fi
if [[ -z "$sdk" && -f "$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg" ]]; then
  sdk="$(cat "$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg")"
fi
if [[ -z "$sdk" ]]; then sdk="$PWD/.tools/sdk"; fi
"$sdk/bin/connectiq"
log="build/tests-$device.log"
# Garmin's runner can return status 1 even when every test passes. Interpret its
# explicit final result, retaining the original runner status on actual errors.
set +e
"$sdk/bin/monkeydo" "build/tests-$device.prg" "$device" -t > "$log" 2>&1
runner_status=$?
set -e
cat "$log"
if rg -q '^PASSED \(passed=[1-9][0-9]*, failed=0, errors=0\)' "$log"; then exit 0; fi
if [[ $runner_status -eq 0 ]]; then exit 1; else exit "$runner_status"; fi
