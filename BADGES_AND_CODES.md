# 🏅 Badges & Promo Codes Configuration — Slime Factory Tycoon

This document outlines the badge structure, promo code configuration, and setup instructions for Roblox Creator Dashboard.

---

## 🎖️ 1. Roblox Badges Setup

Create these badges on the [Roblox Creator Dashboard](https://create.roblox.com/dashboard/creations) under **Badges**:

| Badge Name | Description | Icon Asset | Trigger Condition | Stat Key |
| --- | --- | --- | --- | --- |
| **First Rebirth 🌀** | Perform your very first rebirth in Slime Factory Tycoon! | `assets/icon-256.png` | Rebirth count >= 1 | `rebirths` |
| **10 Rebirths 👑** | Reach 10 total rebirths and master the cycle. | `assets/screenshot-rebirth.png` | Rebirth count >= 10 | `rebirths` |
| **First Legendary 🌟** | Hatch a 1% Legendary Void or Golden Slime! | `assets/screenshot-pets.png` | Hatch Legendary pet | `legendariesHatched` |
| **Slime Master 🧪** | Unlock the Void Foundry final zone! | `assets/banner.png` | Unlock Zone 6 | `zonesUnlocked` >= 6 |
| **Dedicated Player ⏰** | Maintain a 7-day daily login streak! | `assets/icon-512.png` | Login streak >= 7 | `bestStreak` |

### Luau Badge Integration Code Snippet
To hook badges directly to Roblox's `BadgeService`:

```luau
local BadgeService = game:GetService("BadgeService")

local BADGE_IDS = {
	FirstRebirth = 0, -- Replace with real Roblox Badge ID
	TenRebirths = 0,
	FirstLegendary = 0,
}

local function awardBadge(player, badgeId)
	if badgeId > 0 and not BadgeService:UserHasBadgeAsync(player.UserId, badgeId) then
		pcall(function()
			BadgeService:AwardBadge(player.UserId, badgeId)
		end)
	end
end
```

---

## 🎁 2. Launch Promo Codes Index

Promo codes are configured in `src/server/Services/CodeService.luau`.

| Code | Rewards | Expiration | Purpose |
| --- | --- | --- | --- |
| `LAUNCH` | +5,000 Crystals | Permanent | Launch Day marketing & player onboarding |
| `SLIME` | +1,000 Crystals | Permanent | Starter boost for mobile players |
| `THANKS10K` | +2,500 Crystals + 2x Boost (30m) | Permanent | Milestone reward (10k visits) |
| `FRIDAY` | +750 Crystals | Permanent | Weekend community retention boost |
| `LEGENDARY` | 1x Guaranteed Legendary Pet | Permanent | Content creator incentive code |

---

## 🧪 3. Verifying Promo Codes
To test code redemptions in-game or via terminal:
- Redeem code `LAUNCH` -> verified `+5,000 crystals` credited to player save.
- Attempting to redeem `LAUNCH` twice -> verified `Already redeemed!` error message prevents farming.
- Code length > 32 characters -> verified bounded anti-exploit check prevents memory overhead.
