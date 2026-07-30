# Security — the specific ways idle games get robbed

> **Found a vulnerability?** Don't open a public issue — see
> [`.github/SECURITY.md`](.github/SECURITY.md) for private reporting.
> This document is the *threat model*; that one is the *reporting policy*.

Exploiters have full control of the client. Assume every LocalScript is rewritten and every RemoteEvent is called with arbitrary arguments at arbitrary rates. The code in `src/` is built around that assumption; here's the map.

## 1. The one rule

**The client sends intent. The server computes value.**

The Click remote sends a *count of taps*, never an amount of Goo. Even if an exploiter sends `Click(999999)`, the server clamps to 100, then the token bucket grants at most ~40. Their reward is capped at what a fast human could do.

Anti-pattern to never write:
```lua
-- CATASTROPHIC. Never do this.
AddGoo.OnServerEvent:Connect(function(player, amount)
    data.goo += amount
end)
```

## 2. Threats and the mitigation in this codebase

| Threat | Mitigation | Where |
|---|---|---|
| Auto-clicker / click spam | Token bucket at 20 clicks/s, hard clamp of 100 per call, 0.1s remote cooldown | `EconomyService.handleClicks`, `Bootstrap.guard` |
| Forged upgrade ID | `GameConfig.getUpgrade` returns nil for unknown ids → early return | `EconomyService.buyUpgrade` |
| Buying without paying | Cost is recomputed server-side from level; goo deducted before level increments | same |
| Negative / NaN / inf / string args | Explicit `typeof` and `~=` NaN checks on every inbound number | all handlers |
| Buy-amount overflow (`amount = 1e9`) | Clamped to 1..100 | `buyUpgrade` |
| Equipping pets you don't own | uid is verified against `data.pets` before equipping | `PetService.equip` |
| Rolling your own rarity | RNG is entirely server-side; client only receives the result | `PetService.rollPet` |
| Remote spam DoS | Generic per-player, per-remote interval guard wraps every handler | `Bootstrap.guard` |
| Client-side "prompt purchase" abuse | Client sends a *key*, server looks up the real asset id from config | `PromptPurchase` handler |

## 3. Duplication bugs — the two real causes

**(a) Two servers, one profile.** A player joins server A, then quickly joins server B. Both load the same save; whichever saves last wins, and items can be duplicated across the two states. `DataManager` prevents this with a **session lock** stored inside the save (`__lock = {jobId, at}`), written via `UpdateAsync` (atomic read-modify-write). If another live server holds the lock, we refuse to load and kick with a friendly message. Stale locks expire after 5 minutes so a crashed server doesn't lock someone out forever.

Note `UpdateAsync` not `SetAsync`. `SetAsync` has no atomicity and is how you lose data.

**(b) Receipt retries.** Roblox re-delivers a receipt if you don't return `PurchaseGranted`. Grant naively and the player gets the crystals twice. `MonetizationService` keys every receipt by `PurchaseId` in `data.purchaseHistory`, checks it first, and **saves before confirming**. If the save fails we roll back the history entry and return `NotProcessedYet` so Roblox retries later. The player is never charged for nothing, and never granted twice.

Long-term housekeeping: `purchaseHistory` grows forever. Once you're live, trim it to the last ~50 receipts on load, or move it to a bounded ring buffer. A 4MB save limit is far away but not infinite.

## 4. DataStore protection

- `UpdateAsync` everywhere, never `SetAsync` for profiles.
- `pcall` around every call, with exponential backoff (2s/4s/8s).
- **Never save on a failed load.** If load fails we kick instead of starting the player at zero and then overwriting their real save — that's the #1 cause of "I lost everything" reports.
- `BindToClose` saves all players on shutdown with a 25s budget.
- Autosave staggered by 0.3s per player so 30 players don't burst the request budget.
- Version the store name (`SlimeFactory_v1`) so you can wipe test data by bumping to v2.
- `reconcile()` adds new fields to old saves without destroying existing values — this is what lets you ship updates safely.

## 5. What I deliberately did NOT build, and why

- **Kick/ban-on-detection anti-cheat.** False positives from lag will ban real paying players. This code *logs* suspicion and caps rewards instead. Capping is strictly better than banning: the exploiter gains nothing and no legitimate player is harmed.
- **Client-side anti-cheat.** Trivially removed by the exploiter. Pure theatre. Skip it.
- **Obfuscated remotes / randomised names.** Costs you debuggability, delays an attacker by about ninety seconds. Skip it.
- **Encrypting the datastore payload.** Server-only data; the client never sees it. Pointless.

## 6. Content compliance
- Filter every player-authored string with `TextService:FilterStringAsync` before displaying it to anyone else. The current build has no free-text input — keep it that way for as long as possible; it's the single biggest moderation risk removed for free.
- Hatch odds are shown in the Pets panel. Keep them accurate and keep them visible.
- No fake countdown timers, no misleading "value" claims.
