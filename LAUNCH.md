# Launch, discovery, and what to do after

## Release checklist

**Blocking — do not publish without these**
- [ ] API Services enabled; data persists across rejoins (test in a published place, not just Studio)
- [ ] Two-player test passed; session lock kicks a duplicate join cleanly
- [ ] Every gamepass and product ID filled in and **each one purchased once with a test account**
- [ ] Receipt idempotency verified (buy, then force-close mid-purchase, rejoin — no double grant)
- [ ] Offline earnings fire on rejoin and the number is sane
- [ ] Tested on a real phone, not just the emulator
- [ ] Hatch odds displayed and accurate
- [ ] Icon + at least 3 thumbnails uploaded
- [ ] Game description written with keywords
- [ ] Genre set, age rating questionnaire completed
- [ ] Private-server pricing decided (200 Robux is a good default — it's free recurring revenue)

**Nice to have before launch**
- [ ] Badges for first rebirth / 10th rebirth / first legendary (free retention, shows on profiles)
- [ ] A Roblox group so players can join and you can post updates
- [ ] Analytics events wired (see below)

## Discovery / "Roblox SEO"

The algorithm mostly cares about: **click-through rate on your icon**, **D1 retention**, **average session length**, and **update recency**. Keywords help you get surfaced in search; the rest determines whether you get pushed to the front page.

**Title formula:** `[Hook] Slime Factory Tycoon 🟢 [Update Tag]`
Real examples of the pattern that works: `Slime Factory Tycoon 🟢 PETS!`, then next week `... 🟢 NEW ZONE!`. Changing the update tag weekly signals freshness to both players and the algorithm.

Put searchable terms in the **description**, not crammed into the title: tycoon, simulator, clicker, idle, pets, rebirth, afk, tapping.

**Do not** keyword-stuff nonsense or fake "1M visits" claims — it gets games taken down.

## Icon ideas (this is 60% of your success — spend real time here)

Rules: readable at 128px, one focal point, high contrast, a face if possible.

1. A big grinning green slime blob bursting out of a vat, thick black outline, on a solid purple background.
2. Slime character holding a giant glowing crystal, with a "x1000" burst in the corner.
3. Split composition: tiny slime on the left, huge slime on the right, big arrow between them (communicates progression instantly).

Avoid: dark scenes, small text, more than three colours, screenshots of your actual UI.

## Thumbnail ideas (you get up to 10 — use at least 5)

1. **The promise**: giant number `1,000,000,000 GOO/s` with a slime, plus text "GET RICH FAST".
2. **The pets**: grid of all your legendary slimes with rarity glows.
3. **The reward**: "FREE 5,000 CRYSTALS — CODE: LAUNCH" (then actually ship a code system — it's ~30 lines and drives Day-1 installs).
4. **The progression**: the six zones side by side, left to right.
5. **The event**: swap this one out every seasonal event; it's your "we're active" signal.

## Game description template

```
🟢 TAP the vat, earn GOO, and build the biggest slime empire on Roblox!

⭐ REBIRTH for permanent multipliers
🥚 HATCH 15+ pets — Legendaries boost your income massively
🏭 UNLOCK 6 factory zones
💤 EARN GOO WHILE OFFLINE (up to 8 hours!)
🎁 FREE daily rewards — Day 7 gives a GUARANTEED Legendary

🔔 UPDATES EVERY FRIDAY — new pets, zones, and events!
👍 Like & Favourite for more updates
👥 Join the group for codes and early access: [link]

Tags: tycoon, simulator, clicker, idle, afk, pets, rebirth, tapping, factory
```

## Update strategy

**Ship every Friday. Non-negotiable.** Recency is a ranking input and returning players spike on update day.

- Weeks 1–4: 1 new zone OR 3 new pets, plus one balance pass. 15–60 minutes of `GameConfig` edits.
- Every 6 weeks: a seasonal event (themed zone + 3 event pets + event currency). Same code, new numbers and colours.
- Always change the update tag in the title.
- Always post in your group.

**Codes**: add a simple code-redemption remote (server-validated against a hardcoded table, one redemption per player stored in the save). Codes drive social sharing, YouTube coverage, and give you something to put on a thumbnail. Highest ROI feature not already in the codebase.

## Analytics to watch

Roblox's built-in Creator Analytics covers most of it. Watch, in priority order:

1. **D1 retention** — the number that decides whether you have a game. Under 15% means your first 60 seconds is broken; fix onboarding before anything else. Above 25% is strong.
2. **Average session length** — target 12+ minutes. Low means your progression walls arrive too early.
3. **Play-button conversion rate** (visits ÷ impressions) — this is your icon and thumbnails. Under 5% means remake the icon. This is the cheapest fix with the biggest payoff.
4. **Revenue per visit** and **paying-user conversion** — 1–3% of players paying is normal. If conversion is fine but revenue is low, your prices are too low; if conversion is near zero, your shop isn't visible enough or the first purchase is too expensive.
5. **Which products sell** — kill anything that doesn't sell, double down on what does. Expect 2x Goo and the crystal packs to dominate.
6. **Funnel drop-off by rebirth number** — where players quit tells you exactly which wall to soften.

Use `AnalyticsService:LogEconomyEvent` and `LogFunnelStepEvent` for custom funnels (tutorial → first upgrade → first rebirth → first purchase). Free, built in, and it turns guessing into knowing.

## Honest expectations

Most first games earn very little. The realistic path is: launch, read the retention number, fix the first 60 seconds, ship weekly, and keep the loop running long enough for the algorithm to test you with traffic. The people who make money on Roblox are overwhelmingly the ones who shipped update #12, not the ones who had the best idea.

Your third game will earn more than your first. Build this one to learn the pipeline — the codebase here is deliberately reusable for whatever you build next.
