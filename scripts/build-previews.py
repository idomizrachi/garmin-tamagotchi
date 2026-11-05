#!/usr/bin/env python3
"""Build documentation-only scenes with isolated IDs and synthetic values."""
from pathlib import Path
import subprocess
import uuid
from benchmark import ROOT, toolchain


def main():
    sdk, key = toolchain()
    base = (ROOT / "bench/preview-manifest.xml").read_text()
    resources = ROOT / "build/preview-resources"
    resources.mkdir(parents=True, exist_ok=True)
    for pose, name in [(0, "idle"), (4, "coffee"), (7, "running"), (8, "strength"), (10, "recovery")]:
        (resources / "properties.xml").write_text(
            f'<properties><property id="PreviewPose" type="number">{pose}</property></properties>\n')
        app_id = uuid.uuid5(uuid.NAMESPACE_URL,
                            "https://github.com/idomizrachi/garmin-tamagotchi/preview/" + name).hex
        (ROOT / f"build/preview-{name}-manifest.xml").write_text(
            base.replace("00c1b5f1201f49cdae05f34456812890", app_id))
        (ROOT / "build/preview.jungle").write_text(
            f"project.manifest = preview-{name}-manifest.xml\n"
            "base.sourcePath = ../source;../bench\n"
            "base.resourcePath = ../resources;preview-resources\n"
            "base.excludeAnnotations = test\n")
        subprocess.run(["java", "-Xms256m", "-Djava.awt.headless=true", "-Dfile.encoding=UTF-8",
                        "-classpath", str(sdk / "bin/monkeybrains.jar"),
                        "com.garmin.monkeybrains.Monkeybrains", "-f", "build/preview.jungle",
                        "-d", "fr57047mm", "-y", str(key), "-w", "-l", "1", "-r", "-O", "2p",
                        "-o", str(ROOT / f"build/preview-{name}.prg")], cwd=ROOT, check=True)


if __name__ == "__main__":
    main()
