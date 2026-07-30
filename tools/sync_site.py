#!/usr/bin/env python3
"""
Sync this game's manifest and brand art into the linacre.site repository.

The website's Games page renders entirely from `game.manifest.json`, so the
site never contains hand-copied game data. This script is the one-way pipe:

    game repo  --(manifest + webp art)-->  site repo

Run it after any change to the manifest, the changelog, or the brand assets.

    python3 tools/sync_site.py --site ../linacre.site
    python3 tools/sync_site.py --site ../linacre.site --check   # CI mode

`--check` exits non-zero if the site is out of date, without writing anything,
so CI can fail a PR that forgets to sync.
"""

from __future__ import annotations

import argparse
import filecmp
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SLUG = "slime-factory-tycoon"

# (source in game repo, destination relative to site repo root)
ASSETS = [
    ("assets/banner.webp", f"public/games/{SLUG}/banner.webp"),
    ("assets/logo.webp", f"public/games/{SLUG}/logo.webp"),
    ("assets/icon.webp", f"public/games/{SLUG}/icon.webp"),
    ("assets/icon-256.png", f"public/games/{SLUG}/icon-256.png"),
]
MANIFEST_DEST = f"src/data/{SLUG}.json"


def count_code() -> tuple[int, int]:
    files = sorted(ROOT.joinpath("src").rglob("*.luau"))
    lines = sum(len(f.read_text(encoding="utf-8").splitlines()) for f in files)
    return len(files), lines


def refresh_manifest() -> dict:
    """Recompute derived stats so the manifest can never claim stale numbers."""
    path = ROOT / "game.manifest.json"
    data = json.loads(path.read_text(encoding="utf-8"))

    modules, lines = count_code()
    data["stats"]["luauModules"] = modules
    data["stats"]["linesOfLuau"] = lines

    # Counted from the declaration blocks themselves so the numbers can never
    # be stale or wrong. Each list is isolated by its `local X = {` ... `}`
    # boundary, then entries are counted by their `id =` / `key =` field.
    def count_block(text: str, opener: str, field: str) -> int:
        start = text.find(opener)
        if start == -1:
            return 0
        # Anchor on the assignment's opening brace, not the first "{" -- a type
        # annotation like `: { Achievement }` precedes it and would match first.
        eq = text.index("= {", start)
        depth, i = 0, eq + 2
        for j in range(i, len(text)):
            if text[j] == "{":
                depth += 1
            elif text[j] == "}":
                depth -= 1
                if depth == 0:
                    block = text[i : j + 1]
                    return len(re.findall(rf"\b{field}\s*=", block))
        return 0

    content = (ROOT / "src/shared/Content.luau").read_text(encoding="utf-8")
    data["stats"]["achievements"] = count_block(content, "local Achievements", "id")
    data["stats"]["cosmetics"] = count_block(content, "local Cosmetics", "id")

    config = (ROOT / "src/shared/GameConfig.luau").read_text(encoding="utf-8")
    data["stats"]["zones"] = count_block(config, "GameConfig.Zones", "requiredLifetime")
    data["stats"]["pets"] = count_block(config, "GameConfig.Pets", "id")

    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return data


def write_changelog(data: dict) -> None:
    """Regenerate CHANGELOG.md from the manifest.

    Developers look for a changelog at repo root, not inside a JSON file.
    Generating it means the two can never disagree.
    """
    out = [
        "# Changelog\n",
        "All notable changes to this project are documented here.\n",
        "Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); this",
        "project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).\n",
        "> Generated from `game.manifest.json` by `tools/sync_site.py` — edit the",
        "> manifest, not this file.\n",
    ]
    for e in data["changelog"]:
        out.append(f"\n## [{e['version']}] — {e['date']}\n")
        out.append(f"**{e['title']}**\n")
        out.extend(f"- {c}" for c in e["changes"])
        out.append("")
    (ROOT / "CHANGELOG.md").write_text("\n".join(out) + "\n", encoding="utf-8")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--site", required=True, help="path to the linacre.site repo")
    ap.add_argument("--check", action="store_true", help="verify only; exit 1 if stale")
    ap.add_argument("--commit", action="store_true", help="git commit in the site repo")
    args = ap.parse_args()

    site = Path(args.site).expanduser().resolve()
    if not (site / "package.json").exists():
        print(f"error: {site} does not look like the site repo", file=sys.stderr)
        return 2

    data = refresh_manifest()
    write_changelog(data)
    print(f"manifest: {data['stats']['luauModules']} modules, {data['stats']['linesOfLuau']} lines")

    jobs = [("game.manifest.json", MANIFEST_DEST)] + ASSETS
    stale: list[str] = []

    for src_rel, dst_rel in jobs:
        src, dst = ROOT / src_rel, site / dst_rel
        if not src.exists():
            print(f"  missing source: {src_rel}", file=sys.stderr)
            return 2
        same = dst.exists() and filecmp.cmp(src, dst, shallow=False)
        if same:
            print(f"  = {dst_rel}")
            continue
        stale.append(dst_rel)
        if args.check:
            print(f"  STALE {dst_rel}")
        else:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            print(f"  > {dst_rel}")

    if args.check:
        if stale:
            print(f"\n{len(stale)} file(s) out of date. Run: python3 tools/sync_site.py --site {site}")
            return 1
        print("\nsite is up to date.")
        return 0

    if not stale:
        print("\nnothing to do.")
        return 0

    if args.commit:
        subprocess.run(["git", "add", "-A"], cwd=site, check=True)
        subprocess.run(
            ["git", "commit", "-m", f"chore(games): sync {SLUG} manifest and art"],
            cwd=site,
            check=True,
        )
        print("\ncommitted in site repo.")
    else:
        print(f"\nsynced {len(stale)} file(s). Commit them in {site}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
