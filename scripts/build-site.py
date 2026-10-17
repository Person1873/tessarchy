#!/usr/bin/env python3
"""Build the dependency-free GitHub Pages site from repo assets; refuse overwrite."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SHOTS = ("phone-home", "phone-launcher", "phone-switcher", "phone-settings",
         "tablet-home", "desktop-home")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--releases", type=Path, help="Optional public GitHub releases JSON")
    args = parser.parse_args()
    output = args.output.absolute()
    if output.exists() or output.is_symlink():
        parser.error(f"Refusing existing output: {output}")
    sources = [ROOT / "assets/screenshots" / f"{name}.png" for name in SHOTS]
    for path in sources:
        if not path.is_file():
            parser.error(f"Missing screenshot: {path}")
    releases = json.loads(args.releases.read_text()) if args.releases else []
    release = next((item for item in releases if not item.get("draft")), None)
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    output.mkdir(parents=True)
    for name in ("index.html", "style.css", "app.js"):
        shutil.copyfile(ROOT / "website" / name, output / name)
    assets = output / "assets"
    assets.mkdir()
    for source in sources:
        shutil.copyfile(source, assets / source.name)
    shutil.copyfile(ROOT / "shell/artwork/tessarchy-mark.svg", assets / "tessarchy-mark.svg")
    with zipfile.ZipFile(assets / "screenshots.zip", "w", zipfile.ZIP_DEFLATED) as archive:
        for source in sources:
            archive.write(source, source.name)
        archive.write(ROOT / "assets/screenshots/README.md", "README.md")
    (output / "project.json").write_text(json.dumps({"commit": commit, "release": release}) + "\n")
    (output / ".nojekyll").touch()
    print(f"Built {output} from {commit[:7]}")


if __name__ == "__main__":
    main()
