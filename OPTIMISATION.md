# Optimisation — mobile first

Roughly 70–80% of Roblox sessions are on phones and tablets, many of them low-end Android. If it doesn't run at 30fps on a cheap phone, that traffic bounces and your revenue halves. This is a monetization document as much as a technical one.

## Server load

**The rule that matters most: one loop for all players, never one loop per player.**

```lua
-- BAD: 30 players = 30 coroutines all waking up independently
Players.PlayerAdded:Connect(function(p)
    task.spawn(function() while true do task.wait(1) ... end end)
end)

-- GOOD (what EconomyService does): one loop, iterate players
task.spawn(function()
    while true do
        local dt = task.wait(1)
        for _, p in Players:GetPlayers() do ... end
    end
end)
```

Other server measures already in the code:
- **Throttled state sync at 4 Hz.** Firing a remote on every change would be hundreds per second per player. 4 Hz is imperceptible because the client smoothly interpolates the counter.
- **Gamepass ownership cached at join.** `UserOwnsGamePassAsync` is a web call; calling it inside a multiplier function would rate-limit you within minutes.
- **Leaderboard writes every 2 minutes, staggered.** OrderedDataStore limits are strict.
- **No physics, no NPCs, no pathfinding.** The genre's biggest performance advantage — use it.

## Client / mobile

- **Tap batching**: 5 remote calls/second maximum regardless of tap speed.
- **Local prediction**: the counter moves the instant you tap. Latency is invisible.
- **UIScale-based scaling**: one number handles every screen size. No per-device layouts.
- **Thumb-zone layout**: main button lower-centre, nav on the left edge so a right thumb never covers it. Every tap target ≥ 44px.
- **Capped pet rendering (60 cards)**: a player with 800 pets would otherwise create 800 frames and freeze a phone.
- **No `while true do` in the client render path** — only one `RenderStepped` doing cheap arithmetic.

## Load time

Roblox's algorithm is sensitive to join-time drop-off. Targets:
- **Under 6 seconds to interactive.** Achievable trivially here because there's almost no geometry.
- Keep the baseplate small. Delete decorative parts you don't need.
- Set `StreamingEnabled = true` in Workspace **only if** you add a large 3D map. For a UI-driven game it adds complexity with no benefit — skip it for v1.
- Avoid `WaitForChild` without a timeout in critical paths.
- Compress/resize any images before uploading; a 1024×1024 icon is plenty.

## Studio settings to change now
- Rendering → **Quality Level: Automatic** (respects the player's device).
- Lighting → **Technology: Future** looks best but costs mobile fps. Use **ShadowMap**, or **Voxel** if you're targeting the lowest-end devices.
- Workspace → turn off `GlobalShadows` if you're not using them visually.
- Turn off unnecessary particle emitters when the player count is high.

## Built for future updates
- All content lives in `GameConfig` — adding zones/pets/upgrades touches one file.
- `DataManager.reconcile()` means new save fields appear automatically on old profiles.
- Store name is versioned.
- Services are modules with `init()`, so adding a new system is one file plus two lines in `Bootstrap`.

## Skip these (they won't move retention or revenue)
- Custom character animations
- Fancy lighting / post-processing (costs mobile fps, gains nothing in an idle game)
- A large explorable 3D map for v1
- Voice chat, custom chat systems
- Cross-server trading (huge dupe-risk surface for near-zero revenue at your scale)
