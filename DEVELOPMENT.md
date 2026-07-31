# Development Guide

Quick reference for contributors and maintainers.

## Prerequisites

- Git + Roblox Studio
- Python 3 (for balance_sim.py + verify.sh)
- Optional (highly recommended):
  - [Aftman](https://github.com/rojo-rbx/aftman) (or Rokit)
  - Rojo plugin in Studio

## One-command setup

```bash
git clone https://github.com/DLinacre/slime-factory-tycoon.git
cd slime-factory-tycoon
aftman install          # installs pinned rojo, selene, stylua
```

## Daily workflow

### Live editing (recommended)

```bash
rojo serve
```

1. Install **Rojo** plugin in Studio
2. Open the `.rbxlx` from a release **or** create a new place
3. Click **Connect** in the Rojo plugin

Every save in your editor → instantly appears in Studio.

### Full offline build

```bash
rojo build default.project.json --output game.rbxlx
```

## Quality gates (run before every PR)

```bash
./tools/verify.sh
```

This runs (skipping tools you don't have):
- JSON validity
- Balance simulation (`--check`)
- Luau compile (`luau-compile`)
- selene lint
- stylua format check
- Rojo build

## Balance changes

**Always** run the simulator before and after:

```bash
python3 tools/balance_sim.py --hours 6
python3 tools/balance_sim.py --hours 6 --mult 2
```

Paste the **full output** into the PR description.

The CI will fail if:
- Zone 2 takes > 5 minutes
- First rebirth is < 8 or > 30 minutes
- Any stall > 45 minutes

## Adding a new feature

1. Add data to `GameConfig.luau` or `Content.luau` **first**
2. Add a service in `src/server/Services/YourService.luau` (auto-discovered)
3. Add remotes in `src/shared/Net.luau` (declarative + validated)
4. Wire client in `src/client/`
5. Update docs + simulator if numbers changed
6. `./tools/verify.sh`

## File locations

| What                | Path                              | Maps to in Studio                  |
|---------------------|-----------------------------------|------------------------------------|
| Shared logic        | `src/shared/`                     | `ReplicatedStorage/Modules`        |
| Server code         | `src/server/Services/`            | `ServerScriptService/Services`     |
| Bootstrap           | `src/server/Bootstrap.server.luau`| `ServerScriptService/Bootstrap`    |
| Client code         | `src/client/`                     | `StarterPlayer/StarterPlayerScripts` |
| Game design         | `src/shared/GameConfig.luau`      | —                                  |
| Content definitions | `src/shared/Content.luau`         | —                                  |

## Updating the release `.rbxlx`

1. Bump version in `game.manifest.json`
2. Update `CHANGELOG.md` (or let `sync_site.py` do it)
3. `rojo build default.project.json --output SlimeFactoryTycoon-vX.Y.Z.rbxlx`
4. Create GitHub Release + attach the file
5. Update README release badge if needed

## Testing monetization locally

1. Go to **Game Settings → Security → Enable Studio Access to API Services**
2. Create gamepasses / dev products in Creator Dashboard
3. Paste real IDs into `GameConfig.Gamepasses` and `GameConfig.Products`
4. Use `PromptPurchase` remote (handled by `MonetizationService`)

**Never** hardcode purchase logic on the client.

## Common gotchas

- DataStores silently fail without "Studio Access to API Services"
- IDs left at `0` are safely skipped
- Client must only ever send *intent*, never calculated values
- `CosmeticService` has zero access to economy multipliers (by design)
- Session lock kicks duplicate logins — wait 30s

## Debugging

- Use `print` liberally in services (they are server only by default)
- Check **Output** + **Server** tab in Studio
- Run `./tools/verify.sh` first
- Use the balance simulator to validate progression

## Releasing

See `LAUNCH.md` and the checklist in the GitHub release template.

---

**Questions?** Open a Discussion or issue. PRs that pass `./tools/verify.sh` are fast-tracked.
