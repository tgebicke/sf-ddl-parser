#!/usr/bin/env python3
"""
Bump version in pyproject.toml, then commit, push, tag, and push tag.
Usage:
  python scripts/release.py           # patch: 0.1.3 -> 0.1.4
  python scripts/release.py patch    # same
  python scripts/release.py minor    # 0.1.3 -> 0.2.0
  python scripts/release.py major    # 0.1.3 -> 1.0.0
"""

import argparse
import re
import subprocess
import sys
from pathlib import Path


def repo_root() -> Path:
    root = Path(__file__).resolve().parent.parent
    if not (root / "pyproject.toml").exists():
        sys.exit("error: pyproject.toml not found; run from repo root or scripts/")
    return root


def get_version(pyproject_path: Path) -> str:
    text = pyproject_path.read_text()
    m = re.search(r'^version\s*=\s*["\']([^"\']+)["\']', text, re.MULTILINE)
    if not m:
        sys.exit("error: could not find version in pyproject.toml")
    return m.group(1)


def parse_version(version: str) -> tuple[int, int, int]:
    parts = version.strip().split(".")
    if len(parts) != 3:
        sys.exit(f"error: version must be X.Y.Z, got {version!r}")
    try:
        return int(parts[0]), int(parts[1]), int(parts[2])
    except ValueError:
        sys.exit(f"error: version parts must be integers, got {version!r}")


def bump(bump_type: str, major: int, minor: int, patch: int) -> tuple[int, int, int]:
    if bump_type == "patch":
        return major, minor, patch + 1
    if bump_type == "minor":
        return major, minor + 1, 0
    if bump_type == "major":
        return major + 1, 0, 0
    sys.exit(f"error: unknown bump type {bump_type!r}")


def set_version(pyproject_path: Path, new_version: str) -> None:
    text = pyproject_path.read_text()
    new_text = re.sub(
        r'^version\s*=\s*["\'][^"\']+["\']',
        f'version = "{new_version}"',
        text,
        count=1,
        flags=re.MULTILINE,
    )
    if new_text == text:
        sys.exit("error: could not replace version in pyproject.toml")
    pyproject_path.write_text(new_text)


def run(cmd: list[str], cwd: Path) -> None:
    subprocess.run(cmd, cwd=cwd, check=True)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Bump version (patch/minor/major), commit, push, and tag."
    )
    parser.add_argument(
        "bump",
        nargs="?",
        default="patch",
        choices=["patch", "minor", "major"],
        help="Bump type (default: patch)",
    )
    parser.add_argument(
        "--no-push",
        action="store_true",
        help="Commit and tag locally only; do not push",
    )
    args = parser.parse_args()

    root = repo_root()
    pyproject = root / "pyproject.toml"

    current = get_version(pyproject)
    ma, mi, pa = parse_version(current)
    ma, mi, pa = bump(args.bump, ma, mi, pa)
    new_version = f"{ma}.{mi}.{pa}"

    print(f"Bumping version: {current} -> {new_version} ({args.bump})")
    set_version(pyproject, new_version)

    tag = f"v{new_version}"
    run(["git", "add", "pyproject.toml"], cwd=root)
    run(["git", "commit", "-m", f"Release {new_version}"], cwd=root)
    run(["git", "tag", tag, "-m", f"Release {new_version}"], cwd=root)

    if args.no_push:
        print(f"Done. Committed and tagged {tag} locally. Push with:")
        print(f"  git push && git push origin {tag}")
        return

    run(["git", "push"], cwd=root)
    run(["git", "push", "origin", tag], cwd=root)
    print(f"Done. Pushed branch and tag {tag}. Create the release on GitHub to trigger TestPyPI.")


if __name__ == "__main__":
    main()
