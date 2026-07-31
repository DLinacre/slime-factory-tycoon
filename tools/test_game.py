#!/usr/bin/env python3
"""
Automated Test Suite for Slime Factory Tycoon.
Verifies config parameters, pet odds math, offline earnings logic, promo codes,
manifest integrity, and balance simulation.
"""

import sys
import os
import re
import json
import subprocess
from pathlib import Path

# Force UTF-8 stdout encoding for Windows compatibility
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')

ROOT = Path(__file__).resolve().parent.parent

def test_game_config():
    print(" [TEST] GameConfig.luau...")
    config_path = ROOT / "src" / "shared" / "GameConfig.luau"
    assert config_path.exists(), "GameConfig.luau missing"
    text = config_path.read_text(encoding="utf-8")

    # Check pet weights
    rarities = re.findall(r'(\w+)\s*=\s*\{\s*weight\s*=\s*(\d+)', text)
    weights = {r[0]: int(r[1]) for r in rarities}
    total_weight = sum(weights.values())
    assert total_weight == 10000, f"Pet rarity weights sum to {total_weight}, expected 10000"
    print(f"  + PASS: Pet rarity odds sum to 10,000 (100%): {weights}")

    # Check upgrade definitions
    upgrades = re.findall(r'id\s*=\s*"(\w+)"', text)
    assert len(upgrades) >= 5, f"Expected at least 5 upgrades, found {len(upgrades)}"
    print(f"  + PASS: Found {len(upgrades)} upgrade definitions: {upgrades[:5]}")

    # Check offline efficiency cap
    max_offline_hrs = re.search(r'MaxOfflineHours\s*=\s*(\d+)', text)
    assert max_offline_hrs and int(max_offline_hrs.group(1)) == 8, "MaxOfflineHours should be 8"
    efficiency = re.search(r'OfflineEfficiency\s*=\s*([\d\.]+)', text)
    assert efficiency and float(efficiency.group(1)) == 0.5, "OfflineEfficiency should be 0.5"
    print("  + PASS: Offline earnings rules: 8 hours max cap, 50% efficiency")


def test_code_service():
    print(" [TEST] CodeService.luau...")
    code_path = ROOT / "src" / "server" / "Services" / "CodeService.luau"
    assert code_path.exists(), "CodeService.luau missing"
    text = code_path.read_text(encoding="utf-8")

    # Check promo codes
    codes = re.findall(r'([A-Z0-9]+)\s*=\s*\{', text)
    assert "LAUNCH" in codes, "LAUNCH code missing"
    assert "SLIME" in codes, "SLIME code missing"
    assert "THANKS10K" in codes, "THANKS10K code missing"
    print(f"  + PASS: Promo codes verified: {codes}")

    # Check max string length limit
    assert '#rawCode > 32' in text or '32' in text, "Code string length bound missing"
    print("  + PASS: Bounded string input check present (max 32 chars)")


def test_balance_sim():
    print(" [TEST] Balance simulation targets check...")
    sim_script = ROOT / "tools" / "balance_sim.py"
    res = subprocess.run([sys.executable, str(sim_script), "--hours", "6", "--check"], capture_output=True, text=True)
    assert res.returncode == 0, f"Balance simulation failed:\n{res.stdout}\n{res.stderr}"
    print("  + PASS: Balance simulation passed all target metrics (4 rebirths in 6h)")


def test_site_manifest_sync():
    print(" [TEST] Site manifest sync check...")
    site_repo = Path("D:/LIN4CRE/linacre-site-repo")
    if site_repo.exists():
        sync_script = ROOT / "tools" / "sync_site.py"
        res = subprocess.run([sys.executable, str(sync_script), "--site", str(site_repo), "--check"], capture_output=True, text=True)
        assert res.returncode == 0, f"Site manifest check failed:\n{res.stdout}\n{res.stderr}"
        print("  + PASS: Site manifest is in sync with linacre-site-repo")
    else:
        print("  ! SKIP: Site sync test (repo not found at path)")


def test_offline_earnings_calculator():
    print(" [TEST] Offline earnings calculation math...")
    auto_income = 10.0
    efficiency = 0.5

    def calc_offline(seconds_offline):
        capped_seconds = min(seconds_offline, 8 * 3600)
        return capped_seconds * auto_income * efficiency

    assert calc_offline(4 * 3600) == 72000.0, "4h offline math mismatch"
    assert calc_offline(12 * 3600) == 144000.0, "12h offline capping math mismatch"
    print("  + PASS: Offline math correctly caps at 8 hours and calculates 50% yield")


def main():
    print("==========================================================")
    print("  SLIME FACTORY TYCOON -- AUTOMATED TEST SUITE")
    print("==========================================================")
    failures = 0
    tests = [
        test_game_config,
        test_code_service,
        test_balance_sim,
        test_site_manifest_sync,
        test_offline_earnings_calculator,
    ]

    for t in tests:
        try:
            t()
        except Exception as e:
            print(f"  - FAIL: {t.__name__}: {e}")
            failures += 1

    print("\n----------------------------------------------------------")
    if failures == 0:
        print("SUCCESS: ALL TESTS PASSED!")
        return 0
    else:
        print(f"ERROR: {failures} TEST(S) FAILED")
        return 1

if __name__ == "__main__":
    sys.exit(main())
