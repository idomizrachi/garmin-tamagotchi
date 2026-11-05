#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
device="${1:-fr57047mm}"
./scripts/build.sh "$device"
sdk="${CIQ_SDK:-}"
if [[ -z "$sdk" && -d .tools/sdk ]]; then sdk="$PWD/.tools/sdk"; fi
if [[ -z "$sdk" && -f "$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg" ]]; then
  sdk="$(cat "$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg")"
fi
if [[ -z "$sdk" ]]; then sdk="$PWD/.tools/sdk"; fi
"$sdk/bin/connectiq"
"$sdk/bin/monkeydo" "build/LittleCompanion-$device.prg" "$device"
