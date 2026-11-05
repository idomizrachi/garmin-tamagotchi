#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

device="${1:-fr57047mm}"
mode="${2:-release}"
sdk="${CIQ_SDK:-}"
if [[ -z "$sdk" && -d .tools/sdk ]]; then sdk="$PWD/.tools/sdk"; fi
if [[ -z "$sdk" && -f "$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg" ]]; then
  sdk="$(cat "$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg")"
fi
if [[ ! -x "$sdk/bin/monkeyc" ]]; then
  echo 'Set CIQ_SDK to your Connect IQ SDK directory.' >&2; exit 1
fi
key="${DEVELOPER_KEY:-$HOME/personal-dev/garmin/developer_key}"
if [[ ! -f "$key" ]]; then
  echo 'Set DEVELOPER_KEY to your existing Garmin signing key (kept outside this project).' >&2; exit 1
fi
mkdir -p build
compiler=(java -Xms256m -Djava.awt.headless=true -Dfile.encoding=UTF-8
  -classpath "$sdk/bin/monkeybrains.jar" com.garmin.monkeybrains.Monkeybrains)
args=(-f monkey.jungle -d "$device" -y "$key" -w -l 1)
if [[ "$mode" == test ]]; then
  "${compiler[@]}" -f 'monkey.jungle;tests.jungle' -d "$device" -y "$key" -w -l 1 -t -o "build/tests-$device.prg"
elif [[ "$mode" == release ]]; then
  "${compiler[@]}" "${args[@]}" -r -O 2p -o "build/LittleCompanion-$device.prg"
else
  echo 'Usage: scripts/build.sh [device] [release|test]' >&2; exit 1
fi
