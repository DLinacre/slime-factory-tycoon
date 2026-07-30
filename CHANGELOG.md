# Changelog

All notable changes to this project are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); this
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> Generated from `game.manifest.json` by `tools/sync_site.py` — edit the
> manifest, not this file.


## [0.3.0] — 2026-07-30

**Architecture & brand foundation**

- Refactored to an auto-discovering service registry with init/start/player lifecycle
- Added declarative Net layer: per-remote validators and rate limits in one table
- Added Validate module rejecting NaN, infinity, oversized strings and type confusion
- Added achievement system with 16 stat-driven unlocks and automatic reward granting
- Added cosmetic framework with 15 items, structurally unable to affect gameplay balance
- Added generic inventory framework with ownership verification and save-size pruning
- Added server-persisted settings with reduced motion, high contrast, text scale and colour-blind modes
- Added pooled procedural audio engine with pentatonic tap combo pitching
- Added themed UI component library with 44px minimum touch targets
- Established visual identity: logo, icon set, banner, and full brand guidelines
- Published v0.3.0 with a downloadable .rbxlx place file — no toolchain required


## [0.2.0] — 2026-07-30

**Automation**

- Added Rojo project for live Studio sync
- Added CI workflow: lint, balance check, and place-file build artifact
- Added dependency-free Python balance simulator with CI gating
- Added promo code system with server-side validation
- Rebalanced rebirth cost after the simulator found first rebirth at 33 minutes, past the churn point


## [0.1.0] — 2026-07-30

**Initial foundation**

- Core tap-to-earn loop with client prediction and batched remotes
- Five upgrades, six factory zones, rebirth prestige
- Pet hatching with server-side RNG and published odds
- Offline earnings, seven-day daily streak, global leaderboards
- Session-locked DataStore persistence and idempotent receipt handling

