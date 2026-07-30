<div align="center">

![Slime Factory Tycoon](assets/banner.png)

# Slime Factory Tycoon

**A complete, working Roblox idle tycoon you can publish — with the security and save-integrity work already done.**

[![Release](https://img.shields.io/github/v/release/LIN4CRE/slime-factory-tycoon?color=78FF78&label=release)](https://github.com/LIN4CRE/slime-factory-tycoon/releases/latest)
[![Checks](https://img.shields.io/badge/checks-verify.sh%20passing-brightgreen)](tools/verify.sh)
[![Luau](https://img.shields.io/badge/Luau-23%20modules%20compiling-00A2FF?logo=roblox&logoColor=white)](https://luau-lang.org/)
[![Rojo](https://img.shields.io/badge/Rojo-7.4-ff5c5c)](https://rojo.space/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**[⬇ Download the latest `.rbxlx`](https://github.com/LIN4CRE/slime-factory-tycoon/releases/latest)** and open it in Roblox Studio. No toolchain required.

</div>

---

## What this is

A complete, working Roblox game — not a tutorial, not a snippet collection. Tap the vat, earn Goo, buy upgrades, unlock zones, rebirth for permanent multipliers, hatch pets, come back tomorrow for the daily reward.

It's the **idle/incremental** genre, chosen deliberately: it has the best revenue-per-hour-of-work ratio on Roblox for a solo developer, because your content pipeline is a spreadsheet rather than a 3D modelling project. Adding a new zone is one row in a config file. That's what lets you ship weekly, and shipping weekly is what the algorithm rewards.

> **Read [`STRATEGY.md`](STRATEGY.md) first.** It explains why this genre, what the competition looks like, and where the money actually comes from — before you write a line of code.

---

## Highlights

| | |
|---|---|
| **Modular service architecture** | Services are auto-discovered and started in a defined lifecycle. Adding a system means adding a file — `Bootstrap` never changes. |
| **Declarative networking** | Every remote is declared once with its validator and rate limit. Validation you have to remember is validation you'll forget. |
| **Server-authoritative everything** | The client sends *intent* ("I tapped 5 times"), never *value*. Exploiters gain nothing. |
| **Session-locked DataStores** | Atomic `UpdateAsync` locking kills the #1 cause of item duplication. |
| **Idempotent receipts** | `ProcessReceipt` keyed by `PurchaseId`, saved before confirming. No double-grants, no charged-for-nothing. |
| **UI built entirely in code** | Zero manual GUI dragging. Mobile-first, thumb-zone layout, one `UIScale` for every device. |
| **Automated balance testing** | A Python simulator plays the game in CI and fails the build if progression drifts into churn territory. |
| **One-file content pipeline** | Zones, pets, upgrades, prices, odds — all in `GameConfig.luau`. A weekly update is ~15 minutes. |
| **Rojo-native** | `rojo serve` and your editor syncs live into Studio. No copy-pasting. |

---

## Quick start

### Option A — Rojo (recommended, fully automated)

```bash
git clone https://github.com/LIN4CRE/slime-factory-tycoon.git
cd slime-factory-tycoon

# installs rojo, selene, stylua at pinned versions
aftman install          # or: rokit install

# generate a .rbxlx you can just open in Studio
rojo build default.project.json --output game.rbxlx

# ...or live-sync while you edit
rojo serve
```

Then in Studio: install the **Rojo plugin**, click *Connect*. Every file you save appears in Studio instantly.

### Option B — manual paste

No tooling required. Follow [`SETUP.md`](SETUP.md) — it lists the exact Explorer tree and which file goes into which object.

### Then, before you publish

1. Game Settings → Security → **enable Studio Access to API Services** (DataStores fail silently without it).
2. Create your gamepasses and dev products on the Creator Dashboard.
3. Paste the IDs into `GameConfig.luau`, replacing every `id = 0`. *Anything left at `0` is safely skipped, so you can launch with a partial set.*
4. Work through the checklist in [`LAUNCH.md`](LAUNCH.md).

---

## Repository layout

```
slime-factory-tycoon/
├── src/
│   ├── shared/                    → ReplicatedStorage/Modules
│   │   ├── GameConfig.luau        ★ economy, zones, pets, prices
│   │   ├── Content.luau           ★ achievements, cosmetics, settings, seasons
│   │   ├── Theme.luau             ★ colour, type, motion, breakpoints
│   │   ├── Net.luau                 declarative remotes + validators + rate limits
│   │   ├── Validate.luau            composable argument validators
│   │   ├── ServiceRegistry.luau     service locator + lifecycle
│   │   └── Format.luau              number abbreviation (1.2K / 3.4M / 5.6aa)
│   ├── server/                    → ServerScriptService
│   │   ├── Bootstrap.server.luau    build → register → start. Nothing else.
│   │   └── Services/                auto-discovered, no manual wiring
│   │       ├── DataManager.luau         session-locked saves, autosave, BindToClose
│   │       ├── EconomyService.luau      authoritative income, clicks, anti-cheat
│   │       ├── MonetizationService.luau gamepasses + idempotent ProcessReceipt
│   │       ├── PetService.luau          server-side hatch RNG, published odds
│   │       ├── InventoryService.luau    generic UID-keyed containers
│   │       ├── AchievementService.luau  stat-driven unlocks
│   │       ├── CosmeticService.luau     cosmetics (no economy access by design)
│   │       ├── SettingsService.luau     server-persisted, cross-device
│   │       ├── DailyRewardService.luau  7-day streak
│   │       ├── LeaderboardService.luau  OrderedDataStore, throttled
│   │       └── CodeService.luau         promo codes
│   └── client/                    → StarterPlayer/StarterPlayerScripts
│       ├── ClientMain.client.luau   input, prediction, batched remotes
│       ├── UI.luau                  themed component library
│       ├── AudioEngine.luau         pooled procedural SFX
│       └── UIBuilder.luau           screen composition
├── tools/
│   ├── balance_sim.py             progression simulator (runs in CI)
│   ├── sync_site.py               one-way sync to linacre.site
│   └── verify.sh                  every CI gate, locally
├── assets/                        logo · icon set · banner (PNG + WebP)
├── game.manifest.json             machine-readable project data
└── docs → STRATEGY · SETUP · SECURITY · OPTIMISATION · LAUNCH · BRAND
```

## Adding content

The whole point of the architecture. Each of these is a **single row** in a data file, with no other code change:

| To add a… | Edit | Result |
|---|---|---|
| Upgrade | `GameConfig.Upgrades` | Appears in the shop, priced, balanced |
| Zone | `GameConfig.Zones` | Unlocks at its threshold, applies its multiplier |
| Pet | `GameConfig.Pets` | Enters the hatch pool at its rarity weight |
| Achievement | `Content.Achievements` | Tracks its stat, grants its reward automatically |
| Cosmetic | `Content.Cosmetics` | Unlocks by progression, crystals, or Robux |
| Setting | `Content.Settings` | Renders, validates, and persists itself |
| Remote | `Net.REMOTES` | Created, validated, and rate-limited automatically |

Adding a **service** is one file in `src/server/Services/` — it's discovered and started automatically.

---

## The balance simulator

The part I'm most glad exists. It parses `GameConfig.luau` directly — no duplicated numbers — simulates a player, and reports where they'd get stuck.

```bash
$ python3 tools/balance_sim.py --hours 6
==============================================================
  BALANCE SIM  --  6.0h session, 3.0 taps/s, 1.0x mult
==============================================================
  parsed: 5 upgrades, 6 zones
  rebirths reached : 4
  lifetime goo     : 298.69M
  final zone       : Neon Labs
  longest stall    : 2.9 min

  timeline:
        1.38 min   Unlocked Goo Refinery
       11.47 min   Unlocked Toxic Caverns
       21.78 min   Rebirth #1
       56.23 min   Rebirth #2
       77.73 min   Unlocked Neon Labs
      114.52 min   Rebirth #3

  with 2x Goo gamepass:
    rebirths 4 -> 5
    first rebirth 21.8 min -> 10.8 min  (2.01x faster)
    ^ this is your gamepass sales pitch, in numbers

  balance within target ranges.
```

It caught a real bug during development: the original rebirth cost put the first prestige at **33 minutes**, well past where most players quit. Halving it moved it to 22 minutes. That's a retention fix found in a second, without shipping anything.

CI runs `--check`, which exits non-zero if you push a config change that breaks these targets:

- Zone 2 reached in **under 5 minutes** (onboarding)
- First rebirth between **8 and 30 minutes** (meaningful, but reachable)
- No progression stall longer than **45 minutes** (churn wall)

---

## Monetization, in brief

Full reasoning — including *why players actually buy each item* — is in [`STRATEGY.md`](STRATEGY.md).

**Gamepasses:** 2x Goo (199) · Auto-Clicker (149) · VIP (399) · +5 Pet Slots (299) · Lucky Egg (349) · Fast Rebirth (249)

**Dev products:** crystal packs (99 / 499 / 999) · 3x boost (79) · **server-wide boost (199)** · instant rebirth (149) · skip egg cooldown (49)

The server-wide boost is the highest-ROI item here: the buyer gets public thanks, and every other player in the server watches a purchase notification teach them that boosts exist. It's an advertisement that players pay *you* to run.

**Premium Payout** is treated as its own lever — Premium members get a permanent visible 1.25× and a dedicated daily chest. You're not selling them anything; you're buying session time that Roblox pays you for.

---

## Security summary

Full threat model in [`SECURITY.md`](SECURITY.md).

- **Token-bucket click limiting** — 20/s sustained, hard clamp of 100 per call
- **Type/NaN/infinity validation** on every inbound remote argument
- **Server-side lookup** of upgrade costs, pet ownership, and purchase asset IDs
- **Per-player, per-remote rate guard** wrapping every handler
- **Session locking** via atomic `UpdateAsync` (dupe prevention)
- **Receipt idempotency** with save-before-confirm and rollback on save failure
- **Never save on a failed load** — the #1 cause of "I lost everything"

Deliberately *not* included: client-side anti-cheat, remote name obfuscation, auto-banning. They're either trivially bypassed or they punish real players for lag. Capping rewards server-side is strictly better than banning.

---

## Documentation

| Doc | What's in it |
|---|---|
| [STRATEGY.md](STRATEGY.md) | Genre analysis, competition, retention loop, full monetization plan, compliance |
| [SETUP.md](SETUP.md) | Click-by-click Studio setup, object tree, file mapping |
| [SECURITY.md](SECURITY.md) | Exploits, dupe bugs, remote hardening, DataStore protection |
| [OPTIMISATION.md](OPTIMISATION.md) | Mobile-first performance, server load, load times |
| [LAUNCH.md](LAUNCH.md) | Release checklist, Roblox SEO, icon/thumbnail ideas, analytics to watch |
| [BRAND.md](BRAND.md) | Palette semantics, typography, motion, accessibility, voice |

---

## Monetisation ethics

The line is drawn structurally, not by good intentions:

- **`CosmeticService` has no access to the economy multiplier.** Pay-to-win isn't discouraged here, it's *unrepresentable* — a cosmetic physically cannot change income because the code path doesn't exist.
- **No fake timers.** Any countdown is server-authoritative and real.
- **Hatch odds are published in-game**, and the numbers shown are read from the same table the RNG uses.
- **`showOffers` is a setting.** A player can turn every shop popup off permanently, and the game still works.
- **Convenience, not gates.** The Auto-Clicker removes tedium; it doesn't unlock content. Nothing purchasable is required to see any part of the game.

## Accessibility

Not a backlog item. Shipped, persisted server-side, and synced across devices:

- **Reduced Motion** — `UI.tween()` collapses to an instant property set, so *every* animation in the game respects it automatically rather than each call site remembering.
- **High Contrast** — adds borders to interactive surfaces.
- **Text Scale** — 80–150%.
- **Colour-blind modes** — Deuteranopia, Protanopia, Tritanopia.
- **44px minimum touch targets**, enforced in `UI.button`.
- **Rarity is never colour alone** — always paired with a text label.

## Website

The project page at **[linacre.site/games](https://www.linacre.site/games)** renders directly from [`game.manifest.json`](game.manifest.json). `tools/sync_site.py` recomputes the stats from source and copies the manifest and art across, so the website can't drift from the repository — and can't display a number that isn't derived from the code.

Where information genuinely doesn't exist yet (screenshots, the Roblox link), the page shows **"Coming Soon"** or a disabled **"Not Yet Available"** button. No placeholder imagery, no invented player counts.

## Roadmap

- [x] Core loop, rebirths, zones, pets, dailies, leaderboards
- [x] Promo code system
- [x] Rojo project + CI + balance simulator
- [x] Service architecture, declarative networking, content framework
- [x] Achievements, cosmetics, inventory, settings, audio, UI library
- [x] Visual identity + website integration
- [ ] Seasonal event content (framework is in place, no season declared yet)
- [ ] `AnalyticsService` funnel instrumentation
- [ ] Trading (deliberately last — large dupe surface, low revenue at small scale)

---

## Contributing

PRs welcome. CI runs `selene`, `stylua --check`, the balance simulator, and a Rojo build. Run every CI check locally with one command — no tooling required beyond Python
(lint/format/build steps auto-skip if the tools aren't installed):

```bash
./tools/verify.sh
```

> **Note on the CI badge:** GitHub Actions requires Actions minutes to be enabled
> on the account. If the badge shows failing with zero steps executed, that's a
> billing/entitlement issue on the repo owner's account, not the code —
> `./tools/verify.sh` runs the identical checks locally.

---

## Honest expectations

Most first Roblox games earn very little. The realistic path is: launch, read your D1 retention, fix the first 60 seconds, ship every Friday, and stay alive long enough for the algorithm to test you with traffic.

The developers who make money are overwhelmingly the ones who shipped update #12 — not the ones with the best initial idea. This template exists to make updates #2 through #12 cheap.

## Stuck? Ask an AI

<details>
<summary><b>Copy this prompt into any LLM for personalised setup help</b></summary>

The repo is small and well-commented, so an LLM with this context can usually
unblock you faster than an issue can. Paste the following, then describe your
problem:

```
You are helping me set up an open-source Roblox game template called
Slime Factory Tycoon (github.com/LIN4CRE/slime-factory-tycoon).

ARCHITECTURE
- Luau, Rojo project. src/shared -> ReplicatedStorage/Modules,
  src/server -> ServerScriptService, src/client -> StarterPlayerScripts.
- One server Script (Bootstrap) which does: Net.build() to create remotes,
  Registry.registerFolder(Services) to auto-discover services, Registry.start()
  to run init() then start() on all of them.
- Services are ModuleScripts in src/server/Services. They may implement
  init(), start(), onPlayerAdded(player), onPlayerRemoving(player).
  They resolve each other by name via ServiceRegistry.get("Name").
- Remotes are DECLARED in src/shared/Net.luau with a validator and a cooldown.
  Net.onServer(name, handler) applies both automatically.
- All game design values live in src/shared/GameConfig.luau (economy, zones,
  pets, prices) and src/shared/Content.luau (achievements, cosmetics,
  settings, seasons). Never hardcode numbers in service code.

KEY RULES
- The client sends INTENT (e.g. "I tapped 5 times"), never VALUE. Any code
  where the client sends a currency amount is a critical bug.
- CosmeticService must never touch the economy multiplier (no pay-to-win).
- One loop iterating all players, never one loop per player.

COMMON GOTCHAS
- DataStores fail silently unless Game Settings > Security > "Enable Studio
  Access to API Services" is ON. This is the #1 cause of "saving is broken".
- Gamepass/product IDs default to 0 and are skipped. Replace them with real
  IDs from the Creator Dashboard.
- Session locking will kick you if the same account loads on two servers.
  Wait ~30s and rejoin.

VERIFY
- ./tools/verify.sh runs every check (config, balance sim, Luau compile,
  lint, format, manifest sync, Rojo build) and skips tools that aren't
  installed.
- python3 tools/balance_sim.py --hours 6 models progression and fails if the
  first rebirth falls outside 8-30 minutes.

My problem is:
```

This is a convenience, not official support. If the AI is confidently wrong,
[open an issue](https://github.com/LIN4CRE/slime-factory-tycoon/issues) — that's
a documentation bug worth fixing.

</details>

## FAQ

**Can I sell a game made with this?**
Yes. MIT licence, no attribution required, keep all revenue.

**Do I need to credit you?**
No. Appreciated, never required.

**Will this get me moderated on Roblox?**
Nothing here violates Roblox policy. Hatch odds are published in-game, there are
no fake timers, and there's no real-money gambling framing. You remain
responsible for your own content and any changes you make.

**Do I need Rojo?**
No. [Download the `.rbxlx`](https://github.com/LIN4CRE/slime-factory-tycoon/releases/latest)
and open it in Studio. Rojo is only for live-syncing your editor.

**Why isn't there a GitHub Actions badge?**
Actions has no runner minutes on this account, so hosted jobs finish without
executing. Rather than display a badge that reports a failure that isn't real,
the checks run locally — `./tools/verify.sh` runs the identical gates.

**Is this actually production-ready?**
The architecture, security and save handling are. You still need your own art,
your own asset IDs, and a play-test pass before publishing.

**My DataStores aren't saving.**
Game Settings → Security → enable **Studio Access to API Services**. Without it
every DataStore call fails silently and the code looks broken. It isn't.

## License

MIT — see [LICENSE](LICENSE). Use it commercially, keep the Robux, no attribution required.
