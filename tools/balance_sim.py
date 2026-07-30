#!/usr/bin/env python3
"""
Balance simulator for Slime Factory Tycoon.

Parses src/shared/GameConfig.luau directly (no duplicate source of truth) and
simulates a player session to answer the questions that actually decide whether
an idle game retains and earns:

  * How long until the first rebirth?  (target: 12-25 min -- fast enough to hook)
  * How long until zone 2?             (target: under 3 min)
  * Does progression stall anywhere?   (a wall > 45 min = churn point)
  * What does a 2x-Goo buyer save?     (that's the pitch that sells the pass)

Usage:
    python3 tools/balance_sim.py
    python3 tools/balance_sim.py --hours 24 --mult 2 --json

Zero dependencies. Runs in CI on every push so a bad balance change fails loudly.
"""

from __future__ import annotations

import argparse
import json
import math
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

CONFIG_PATH = Path(__file__).resolve().parent.parent / "src" / "shared" / "GameConfig.luau"

# Health thresholds. CI fails if the balance drifts outside these.
TARGETS = {
    "zone2_minutes_max": 5.0,
    "first_rebirth_minutes_min": 8.0,
    "first_rebirth_minutes_max": 30.0,
    "max_stall_minutes": 45.0,
}


def _num(raw: str) -> float:
    return float(raw.strip())


@dataclass
class Upgrade:
    id: str
    name: str
    base_cost: float
    growth: float
    add_click: float
    add_auto: float
    max_level: int
    level: int = 0

    def cost(self) -> float:
        return math.floor(self.base_cost * (self.growth**self.level))


@dataclass
class Zone:
    id: int
    name: str
    required: float
    mult: float


@dataclass
class Config:
    upgrades: list[Upgrade] = field(default_factory=list)
    zones: list[Zone] = field(default_factory=list)
    base_click: float = 1.0
    rebirth_base: float = 1e5
    rebirth_growth: float = 4.5
    mult_per_rebirth: float = 0.5


def parse_config(path: Path) -> Config:
    """Deliberately regex-based: keeps the Luau file the single source of truth
    without needing a Lua runtime in CI."""
    text = path.read_text(encoding="utf-8")
    cfg = Config()

    m = re.search(r"BaseClickPower\s*=\s*([\d.eE+-]+)", text)
    if m:
        cfg.base_click = _num(m.group(1))

    for m in re.finditer(
        r'\{\s*id\s*=\s*"(\w+)"\s*,\s*name\s*=\s*"([^"]+)"\s*,\s*baseCost\s*=\s*([\d.eE+-]+)\s*,'
        r"\s*growth\s*=\s*([\d.eE+-]+)\s*,\s*addClick\s*=\s*([\d.eE+-]+)\s*,"
        r"\s*addAuto\s*=\s*([\d.eE+-]+)\s*,\s*maxLevel\s*=\s*(\d+)",
        text,
    ):
        cfg.upgrades.append(
            Upgrade(
                id=m.group(1),
                name=m.group(2),
                base_cost=_num(m.group(3)),
                growth=_num(m.group(4)),
                add_click=_num(m.group(5)),
                add_auto=_num(m.group(6)),
                max_level=int(m.group(7)),
            )
        )

    for m in re.finditer(
        r'\{\s*id\s*=\s*(\d+)\s*,\s*name\s*=\s*"([^"]+)"\s*,'
        r"\s*requiredLifetime\s*=\s*([\d.eE+-]+)\s*,\s*incomeMult\s*=\s*([\d.eE+-]+)",
        text,
    ):
        cfg.zones.append(Zone(int(m.group(1)), m.group(2), _num(m.group(3)), _num(m.group(4))))

    m = re.search(r"Rebirth\s*=\s*\{(.*?)\n\}", text, re.S)
    if m:
        blk = m.group(1)
        for key, attr in (
            ("baseCost", "rebirth_base"),
            ("growth", "rebirth_growth"),
            ("multPerRebirth", "mult_per_rebirth"),
        ):
            mm = re.search(rf"{key}\s*=\s*([\d.eE+-]+)", blk)
            if mm:
                setattr(cfg, attr, _num(mm.group(1)))

    return cfg


def fmt(v: float) -> str:
    if v < 1000:
        return f"{v:.0f}"
    units = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp"]
    t = min(int(math.log(v, 1000)), len(units) - 1)
    return f"{v / 1000**t:.2f}{units[t]}"


def simulate(cfg: Config, hours: float, extra_mult: float, cps: float, verbose: bool) -> dict:
    """Greedy-but-sane player model: buys the upgrade with the best
    income-per-goo ratio whenever affordable. Real players are worse than this,
    so treat results as a best case."""
    dt = 1.0
    steps = int(hours * 3600 / dt)

    goo = 0.0
    lifetime = 0.0
    zone_idx = 0
    rebirths = 0
    for u in cfg.upgrades:
        u.level = 0

    events: list[dict] = []
    milestones: dict[str, float] = {}
    last_progress_t = 0.0
    max_stall = 0.0

    def multiplier() -> float:
        z = cfg.zones[zone_idx].mult if cfg.zones else 1.0
        return (1 + rebirths * cfg.mult_per_rebirth) * z * extra_mult

    def click_power() -> float:
        return (cfg.base_click + sum(u.level * u.add_click for u in cfg.upgrades)) * multiplier()

    def auto_income() -> float:
        return sum(u.level * u.add_auto for u in cfg.upgrades) * multiplier()

    for step in range(steps):
        t = step * dt
        income = auto_income() * dt + click_power() * cps * dt
        goo += income
        lifetime += income

        # zone unlock
        while zone_idx + 1 < len(cfg.zones) and lifetime >= cfg.zones[zone_idx + 1].required:
            zone_idx += 1
            key = f"zone{cfg.zones[zone_idx].id}"
            if key not in milestones:
                milestones[key] = t / 60
                events.append({"t_min": round(t / 60, 2), "event": f"Unlocked {cfg.zones[zone_idx].name}"})
            last_progress_t = t

        # buy best-value upgrade
        bought = True
        while bought:
            bought = False
            best, best_ratio = None, 0.0
            for u in cfg.upgrades:
                if u.level >= u.max_level:
                    continue
                c = u.cost()
                if c <= goo and c > 0:
                    gain = u.add_auto + u.add_click * cps
                    ratio = gain / c
                    if ratio > best_ratio:
                        best, best_ratio = u, ratio
            if best:
                goo -= best.cost()
                best.level += 1
                bought = True
                last_progress_t = t

        # rebirth when affordable
        rc = cfg.rebirth_base * (cfg.rebirth_growth**rebirths)
        if goo >= rc:
            rebirths += 1
            goo = 0.0
            for u in cfg.upgrades:
                u.level = 0
            key = f"rebirth{rebirths}"
            if rebirths <= 5:
                milestones[key] = t / 60
                events.append({"t_min": round(t / 60, 2), "event": f"Rebirth #{rebirths}"})
            last_progress_t = t

        stall = (t - last_progress_t) / 60
        max_stall = max(max_stall, stall)

    return {
        "hours": hours,
        "extra_mult": extra_mult,
        "cps": cps,
        "rebirths": rebirths,
        "lifetime_goo": fmt(lifetime),
        "final_zone": cfg.zones[zone_idx].name if cfg.zones else "-",
        "milestones_min": {k: round(v, 2) for k, v in milestones.items()},
        "max_stall_min": round(max_stall, 2),
        "events": events[:25],
    }


def check_health(result: dict) -> list[str]:
    problems = []
    ms = result["milestones_min"]

    z2 = ms.get("zone2")
    if z2 is None:
        problems.append("Player never reached Zone 2 -- early game is far too slow.")
    elif z2 > TARGETS["zone2_minutes_max"]:
        problems.append(f"Zone 2 took {z2:.1f} min (target < {TARGETS['zone2_minutes_max']}). Onboarding too slow; players churn in the first 5 minutes.")

    r1 = ms.get("rebirth1")
    if r1 is None:
        problems.append("Player never rebirthed -- the core retention loop is unreachable.")
    else:
        if r1 < TARGETS["first_rebirth_minutes_min"]:
            problems.append(f"First rebirth at {r1:.1f} min (target > {TARGETS['first_rebirth_minutes_min']}). Too cheap; the prestige feels meaningless.")
        if r1 > TARGETS["first_rebirth_minutes_max"]:
            problems.append(f"First rebirth at {r1:.1f} min (target < {TARGETS['first_rebirth_minutes_max']}). Too far away; most players quit before seeing it.")

    if result["max_stall_min"] > TARGETS["max_stall_minutes"]:
        problems.append(f"Longest stall {result['max_stall_min']:.1f} min with no progress (target < {TARGETS['max_stall_minutes']}). That's a churn wall.")

    return problems


def main() -> int:
    ap = argparse.ArgumentParser(description="Simulate Slime Factory Tycoon progression.")
    ap.add_argument("--hours", type=float, default=6.0)
    ap.add_argument("--mult", type=float, default=1.0, help="extra multiplier, e.g. 2 for the 2x Goo pass")
    ap.add_argument("--cps", type=float, default=3.0, help="average taps per second (3 = casual)")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--check", action="store_true", help="exit 1 if balance targets are violated")
    args = ap.parse_args()

    if not CONFIG_PATH.exists():
        print(f"error: {CONFIG_PATH} not found", file=sys.stderr)
        return 2

    cfg = parse_config(CONFIG_PATH)
    if not cfg.upgrades or not cfg.zones:
        print("error: failed to parse upgrades/zones from GameConfig.luau", file=sys.stderr)
        return 2

    free = simulate(cfg, args.hours, args.mult, args.cps, False)

    if args.json:
        print(json.dumps(free, indent=2))
    else:
        print("=" * 62)
        print(f"  BALANCE SIM  --  {args.hours}h session, {args.cps} taps/s, {args.mult}x mult")
        print("=" * 62)
        print(f"  parsed: {len(cfg.upgrades)} upgrades, {len(cfg.zones)} zones")
        print(f"  rebirths reached : {free['rebirths']}")
        print(f"  lifetime goo     : {free['lifetime_goo']}")
        print(f"  final zone       : {free['final_zone']}")
        print(f"  longest stall    : {free['max_stall_min']:.1f} min")
        print("\n  timeline:")
        for e in free["events"]:
            print(f"    {e['t_min']:>8.2f} min   {e['event']}")

        # The monetization question: what does the 2x pass actually buy you?
        if args.mult == 1.0:
            paid = simulate(cfg, args.hours, 2.0, args.cps, False)
            print("\n  with 2x Goo gamepass:")
            print(f"    rebirths {free['rebirths']} -> {paid['rebirths']}")
            r_free = free["milestones_min"].get("rebirth1")
            r_paid = paid["milestones_min"].get("rebirth1")
            if r_free and r_paid:
                print(f"    first rebirth {r_free:.1f} min -> {r_paid:.1f} min  ({r_free / r_paid:.2f}x faster)")
            print("    ^ this is your gamepass sales pitch, in numbers")

    problems = check_health(free)
    if problems:
        print("\n  BALANCE WARNINGS:")
        for p in problems:
            print(f"    ! {p}")
        if args.check:
            return 1
    else:
        print("\n  balance within target ranges.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
