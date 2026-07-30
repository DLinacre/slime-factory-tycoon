# Studio Setup — click by click

You need **zero** paid tools. Roblox Studio is free. That's it.

## 1. Create the place
1. Studio → New → **Baseplate**.
2. File → Save to Roblox → name it. Publish now so DataStores work (they don't run in an unpublished place).
3. Home → Game Settings → **Security** → turn ON **Enable Studio Access to API Services**. Without this, every DataStore call fails in Studio and you'll think your code is broken. It isn't.

## 2. Build the tree

In the Explorer, create exactly this:

```
ReplicatedStorage
└── Modules              (Folder)
    ├── GameConfig       (ModuleScript)
    └── Format           (ModuleScript)

ServerScriptService
├── Bootstrap            (Script)          <- server Script, RunContext = Legacy/Server
└── Services             (Folder)
    ├── DataManager      (ModuleScript)
    ├── EconomyService   (ModuleScript)
    ├── MonetizationService (ModuleScript)
    ├── PetService       (ModuleScript)
    ├── DailyRewardService  (ModuleScript)
    └── LeaderboardService  (ModuleScript)

StarterPlayer
└── StarterPlayerScripts
    ├── ClientMain       (LocalScript)
    └── UIBuilder        (ModuleScript)
```

**How to create each one:** hover the parent in Explorer → click the ⊕ → pick Script / LocalScript / ModuleScript / Folder → rename it to match exactly (names are case-sensitive in the `require` calls).

## 3. Paste the code

Open each file from `src/` in this workspace and paste it into the matching object.

| Workspace file | Studio object |
|---|---|
| `src/ReplicatedStorage/Modules/GameConfig.lua` | ReplicatedStorage/Modules/GameConfig |
| `src/ReplicatedStorage/Modules/Format.lua` | ReplicatedStorage/Modules/Format |
| `src/ServerScriptService/Bootstrap.server.lua` | ServerScriptService/Bootstrap |
| `src/ServerScriptService/DataManager.lua` | ServerScriptService/Services/DataManager |
| `src/ServerScriptService/EconomyService.lua` | .../EconomyService |
| `src/ServerScriptService/MonetizationService.lua` | .../MonetizationService |
| `src/ServerScriptService/PetService.lua` | .../PetService |
| `src/ServerScriptService/DailyRewardService.lua` | .../DailyRewardService |
| `src/ServerScriptService/LeaderboardService.lua` | .../LeaderboardService |
| `src/StarterPlayerScripts/ClientMain.client.lua` | StarterPlayerScripts/ClientMain (LocalScript) |
| `src/StarterPlayerScripts/UIBuilder.lua` | StarterPlayerScripts/UIBuilder (ModuleScript) |

**Do not create the Remotes folder by hand** — `Bootstrap` creates it and every RemoteEvent at runtime.

## 4. Make the gamepasses and products

Creator Dashboard → your game → **Monetization**.

- **Passes** → Create a Pass, for each of the 6 in `GameConfig.Gamepasses`. Copy each pass's ID from its URL.
- **Developer Products** → Create for each entry in `GameConfig.Products`. Copy the IDs.

Then paste those numbers into `GameConfig` replacing every `id = 0`. **Anything left at 0 is simply skipped** — the code checks for it, so you can launch with a partial set and add more later without errors.

## 5. Test

1. Test → **Start** with 2 players (this catches session-lock and remote bugs that solo testing hides).
2. Tap the vat, buy upgrades, rebirth, hatch.
3. Leave and rejoin: your data should persist and you should see the offline-earnings banner.
4. Test → Device emulation → **iPhone**. Check every button is reachable with a thumb and no text is clipped.

## 6. Art (the fastest free path)

You do not need to model anything. For v1:
- The vat is a coloured circle with a `UICorner` — already done in code.
- Pets are coloured cards — already done in code.
- Later, upgrade to real art via free Toolbox meshes (filter to *Creator: Roblox* or verified creators only) or generate icons and upload them as Decals.

Ship with programmer art. Replace art in week 2 once you know people are playing. Do not spend week 1 on a slime model.

## 7. Where to change things

- **Balance / prices / pets / zones** → `GameConfig` only. Never hardcode numbers elsewhere.
- **New upgrade** → one row in `GameConfig.Upgrades`. The UI builds itself.
- **New pet** → one row in `GameConfig.Pets`.
- **New zone** → one row in `GameConfig.Zones`.

That's the whole content pipeline. A weekly update is ~15 minutes of editing one file.
