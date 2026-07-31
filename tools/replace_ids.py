#!/usr/bin/env python3
"""
Quick helper to replace placeholder Gamepass / Dev Product IDs.

Usage:
    python3 tools/replace_ids.py

It will ask for your IDs and update src/shared/GameConfig.luau in place.
Safe — only touches the id = 0 entries.
"""

import re
from pathlib import Path

CONFIG = Path(__file__).parent.parent / "src" / "shared" / "GameConfig.luau"

def main():
    if not CONFIG.exists():
        print("❌ GameConfig.luau not found")
        return

    text = CONFIG.read_text()

    print("🔧 Slime Factory Tycoon — ID Replacer")
    print("This will replace id = 0 placeholders with your real asset IDs.\n")

    # Find all gamepasses and products
    gamepasses = re.findall(r'(\w+)\s*=\s*\{[^}]*id\s*=\s*0', text)
    products = re.findall(r'(\w+)\s*=\s*\{[^}]*id\s*=\s*0', text.split("Products")[1] if "Products" in text else "")

    print("Gamepasses found with id=0:")
    for gp in set(gamepasses):
        print(f"  - {gp}")

    print("\nDev Products found with id=0:")
    for p in set(products):
        print(f"  - {p}")

    print("\nEnter your IDs from the Creator Dashboard (press Enter to skip):")

    replacements = {}

    for match in re.finditer(r'(\w+)\s*=\s*\{[^}]*id\s*=\s*0([^,]*)', text):
        name = match.group(1)
        if name in replacements:
            continue
        val = input(f"  {name} ID (number): ").strip()
        if val.isdigit():
            replacements[name] = val

    if not replacements:
        print("No IDs provided. Nothing changed.")
        return

    new_text = text
    for name, new_id in replacements.items():
        # Replace only the id = 0 for that specific entry
        pattern = rf'({name}\s*=\s*\{{[^}]*?)id\s*=\s*0'
        new_text = re.sub(pattern, rf'\1id = {new_id}', new_text, count=1)

    CONFIG.write_text(new_text)
    print(f"\n✅ Updated {len(replacements)} IDs in GameConfig.luau")
    print("Remember to test purchases in Studio!")

if __name__ == "__main__":
    main()
