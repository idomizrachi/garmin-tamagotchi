#!/usr/bin/env python3
"""Build/run the isolated simulator benchmark; never install it on the watch."""
import argparse
import os
from pathlib import Path
import signal
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]


def toolchain():
    sdk = os.environ.get("CIQ_SDK")
    if not sdk and (ROOT / ".tools/sdk").is_dir():
        sdk = str(ROOT / ".tools/sdk")
    if not sdk:
        sdk = (Path.home() / "Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg").read_text().strip()
    key = Path(os.environ.get("DEVELOPER_KEY", str(Path.home() / "personal-dev/garmin/developer_key")))
    if not key.is_file():
        raise SystemExit("Set DEVELOPER_KEY to your Garmin signing key.")
    return Path(sdk), key


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--device", choices=["fr57047mm", "fr57042mm"], default="fr57047mm")
    parser.add_argument("--build-only", action="store_true")
    args = parser.parse_args()
    sdk, key = toolchain()
    binary = ROOT / f"build/performance-{args.device}.prg"
    binary.parent.mkdir(exist_ok=True)
    subprocess.run(["java", "-Xms256m", "-Djava.awt.headless=true", "-Dfile.encoding=UTF-8",
                    "-classpath", str(sdk / "bin/monkeybrains.jar"),
                    "com.garmin.monkeybrains.Monkeybrains", "-f", "bench/performance.jungle",
                    "-d", args.device, "-y", str(key), "-w", "-l", "1", "-r", "-O", "2p",
                    "-o", str(binary)], cwd=ROOT, check=True)
    if args.build_only:
        return
    subprocess.run([str(sdk / "bin/connectiq")], check=True)
    log_path = ROOT / f"build/performance-{args.device}.log"
    # Run only our own runner in its own process group so its lingering shell
    # connection can be closed once the benchmark explicitly reports completion.
    with log_path.open("w") as log:
        process = subprocess.Popen([str(sdk / "bin/monkeydo"), str(binary), args.device],
                                   stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        deadline = time.monotonic() + 90
        try:
            while time.monotonic() < deadline:
                text = log_path.read_text()
                if "PERF_DONE" in text:
                    print(text)
                    return
                if process.poll() is not None:
                    raise SystemExit(text or "Simulator runner exited without PERF_DONE.")
                time.sleep(0.2)
            raise SystemExit("Benchmark timed out. Check that the simulator is running and its previous app is stopped.")
        finally:
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGTERM)
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.wait()


if __name__ == "__main__":
    main()
