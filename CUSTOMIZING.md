# Customizing Slime Factory Tycoon

This guide shows how to turn the template into **your own published game** in ~30-60 minutes of focused work (plus art + testing).

> The architecture is deliberately built so almost everything is data. You rarely edit service code.

---

## 1. The absolute minimum (get a playable game)

1. **Download** the latest `.rbxlx` from [Releases](https://github.com/DLinacre/slime-factory-tycoon/releases/latest)
2. Open in Roblox Studio
3. **Game Settings → Security → Enable "Studio Access to API Services"**
4. Replace placeholder IDs (see below)
5. Publish!

---

## 2. Replace all placeholder IDs (5 minutes)

Open `src/shared/GameConfig.luau` (or the version inside the `.rbxlx`).

### Gamepasses

```luau
GameConfig.Gamepasses = {
    DoubleGoo    = { id = 12345678, ... },   -- ← your ID
    ...
}
```

### Developer Products

```luau
GameConfig.Products = {
    Crystals1k = { id = 9876543, ... },
    ...
}
```

**How to get IDs:**
1. Creator Dashboard → Monetization → Gamepasses / Developer Products
2. Copy the **Asset ID** (the number at the end of the URL)

Anything left at `id = 0` is safely ignored.

---

## 3. Rebrand the game (15–30 minutes)

### Visual identity

Edit these files:

| File                    | What to change                              |
|-------------------------|---------------------------------------------|
| `src/shared/Theme.luau` | Primary/accent colours, fonts               |
| `assets/`               | Replace `banner.png`, `logo.png`, icons     |
| `GameConfig.luau`       | `name`, currency names ("Goo" → "Mana", etc) |

**Pro tip**: Keep the same folder structure for `assets/`. The website sync and README will just work.

### Rename everything

- Search & replace in `GameConfig.luau`:
  - `"Goo"` → your currency
  - `"Slime"` → your theme
  - Zone names, pet names, etc.

- Update `Content.luau` for achievements, cosmetics, settings labels.

- Change the place name in Studio.

---

## 4. Balance for your game (use the simulator!)

```bash
python3 tools/balance_sim.py --hours 6
```

Targets the simulator enforces:
- Zone 2 in < 5 minutes
- First rebirth 8–30 minutes
- No stall > 45 minutes

**To tune**:
- Change `baseCost`, `growth`, `requiredLifetime`, `Rebirth.baseCost` in `GameConfig.luau`
- Rerun the simulator
- Commit when it passes `--check`

Example: Want a faster early game? Lower early `baseCost` values.

---

## 5. Add your own content (no code changes)

### New upgrade

```luau
-- In GameConfig.Upgrades
{ id = "mega", name = "Mega Pump", baseCost = 500000, growth = 1.3, addClick = 0, addAuto = 400, maxLevel = 100 },
```

### New zone

```luau
{ id = 7, name = "Crystal Core", requiredLifetime = 1e12, incomeMult = 20.0 },
```

### New pet

```luau
{ id = "crystal_slime", name = "Crystal Slime", rarity = "Epic", mult = 1.8, icon = "rbxassetid://YOUR_ID" },
```

### New achievement

In `Content.luau`:

```luau
{ id = "zone_master", name = "Zone Master", desc = "Unlock 5 zones", stat = "zonesUnlocked", goal = 5, crystals = 800 },
```

All systems automatically pick up new rows.

---

## 6. Monetization checklist

- Create **6–8 gamepasses** (prices already suggested in `GameConfig`)
- Create **5–7 dev products**
- Set realistic prices (see `STRATEGY.md`)
- Add a **Server Boost** product — it’s the highest-ROI item

**Important**: The server-wide boost notifies every player when someone buys it. This is intentional advertising.

---

## 7. Art & Polish (the real work)

- Replace all placeholder `icon = "rbxassetid://0"`
- Create proper thumbnails (1400×1400) and icons (512×512)
- Record short gameplay video for the place page
- Write compelling description + update tags

See `LAUNCH.md` for the full checklist.

---

## 8. Testing before publish

```bash
./tools/verify.sh          # must pass
```

Manual testing checklist:
- [ ] DataStores save/load across rejoins
- [ ] Offline earnings work
- [ ] Purchases grant correctly (use test purchases)
- [ ] Rebirths feel good (use simulator numbers)
- [ ] Mobile layout is usable
- [ ] Accessibility modes don't break anything

---

## 9. Publishing

1. Publish the place to Roblox
2. Set the **Game Icon**, **Thumbnails**, **Description**
3. Enable **Monetization** features
4. Add to a **Group** if you want (recommended for most games)
5. Turn on **Premium Payouts** benefits

Update `game.manifest.json` later when you have a real Roblox link.

---

## 10. Keeping your fork up to date

```bash
git remote add upstream https://github.com/DLinacre/slime-factory-tycoon.git
git fetch upstream
git merge upstream/main
```

Only merge if you haven't heavily customized core services.

---

## Quick reference: files you will edit most

| File                        | Purpose                              | Frequency |
|-----------------------------|--------------------------------------|---------|
| `GameConfig.luau`           | All economy, prices, pets, zones     | Weekly  |
| `Content.luau`              | Achievements, cosmetics, settings    | Weekly  |
| `Theme.luau`                | Colours & motion                     | Rarely  |
| `Net.luau`                  | New remotes (rare)                   | Rarely  |
| Your own service            | New gameplay systems                 | As needed |

---

**You now have everything you need to launch.**

The hard parts (saving, security, monetization, balance tooling) are already solved.

Focus on:
- Your theme & art
- Your numbers (via simulator)
- Your launch thumbnails + description

Good luck — and ship weekly! 🚀

If you get stuck, paste the AI prompt from the README into any LLM.