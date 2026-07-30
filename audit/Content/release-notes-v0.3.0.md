# v0.3.0 — Architecture & brand foundation

A complete, working Roblox idle-tycoon you can open in Studio and publish — with
the security and save-integrity work already done.

## 📦 Getting started in 30 seconds

Download **`SlimeFactoryTycoon-v0.3.0.rbxlx`** below and open it in Roblox
Studio. That's it — no toolchain required.

Prefer live-sync? `aftman install && rojo serve`.

Then enable **Game Settings → Security → Studio Access to API Services**, or
DataStores fail silently and you'll think the code is broken.

## What's in this release

### Architecture
- **Service registry** — services are auto-discovered and started in a defined
  `init → start → player` lifecycle. Adding a system means adding a file;
  `Bootstrap` never changes.
- **Declarative networking** — every remote is declared once with its validator
  and rate limit attached. Validation you have to remember is validation you'll
  eventually forget.
- **Argument validation** — rejects NaN, ±infinity, type confusion, and
  oversized strings on every inbound remote.

### Gameplay systems
- Tap-to-earn loop with client prediction and batched remotes
- 5 upgrades · 6 zones · rebirth prestige · 10 pets across 4 rarities
- Offline earnings (8h cap) · 7-day daily streak · promo codes
- 16 stat-driven achievements that grant rewards automatically
- 15 cosmetics — vat skins, goo colours, trails, titles
- Global OrderedDataStore leaderboards

### Security
- Session-locked DataStores via atomic `UpdateAsync` — prevents the cross-server
  duplication that plagues idle games
- Idempotent `ProcessReceipt` keyed by `PurchaseId`, save-before-confirm with
  rollback, so players are never double-charged or charged for nothing
- Token-bucket click limiting: 20/s sustained, hard clamp of 100 per call
- Never saves on a failed load — the classic cause of "I lost everything"

### Accessibility
Reduced Motion, High Contrast, 80–150% text scale, and three colour-blind modes
— all persisted **server-side** so they follow the player across devices.
`UI.tween()` collapses to an instant set under Reduced Motion, so the setting
can't be forgotten per-call-site.

### Monetisation ethics
`CosmeticService` has **no access to the economy multiplier**. Pay-to-win isn't
discouraged here — it's structurally unrepresentable. Hatch odds are published
in-game and read from the same table the RNG uses.

### Tooling
- **Balance simulator** — a dependency-free Python model that plays the game in
  CI and fails the build if progression drifts into churn territory. It caught a
  real problem during development: the original rebirth cost put first prestige
  at 33 minutes, past the point most players quit. Now 22.
- Rojo project for live Studio sync
- `tools/verify.sh` runs every CI gate locally

## Known limitations

- **CI badge shows failing.** GitHub Actions has no runner minutes on this
  account; all jobs finish with zero steps executed. Every check passes locally
  via `./tools/verify.sh`. This is a billing issue, not a code defect.
- **Gamepass and product IDs are placeholders.** Replace every `id = 0` in
  `GameConfig.luau` with your own from the Creator Dashboard. Anything left at
  `0` is safely skipped, so you can launch with a partial set.
- **No seasonal content yet.** The framework is in place; `Content.Seasons` is
  deliberately empty rather than filled with placeholder data.
- **Not yet published to Roblox**, so there are no player-facing metrics to
  report.

## Full changelog

See [`game.manifest.json`](https://github.com/LIN4CRE/slime-factory-tycoon/blob/main/game.manifest.json) or the
[project page](https://www.linacre.site/games).

**MIT licensed.** Use it commercially, keep the Robux, no attribution required.
