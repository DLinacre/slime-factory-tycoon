# Executive Summary

**Target:** Slime Factory Tycoon — open-source Roblox idle-tycoon template
**Surfaces:** `github.com/LIN4CRE/slime-factory-tycoon` (repo) + `linacre.site/games` (project page)
**Date:** 2026-07-30 · **Depth:** Full professional

> ⚠️ The brief auto-resolved the product name as "Github" and the market as
> `[object Object]`. Both are wrong and are corrected in
> [`Assumptions-and-Gaps.md`](Assumptions-and-Gaps.md). GitHub is the *host*, not
> the product.

---

## Overall score: **72 / 100**

A genuinely well-engineered project with an unusually strong technical
foundation, held back almost entirely by **being brand new and having no
distribution**. The code and documentation would pass review at most studios.
The project has zero stars, zero releases, and the game it showcases isn't
published — so the gap isn't quality, it's *proof*.

| # | Category | Score | One-line verdict |
|---|---|---:|---|
| 1 | Executive Summary | 72 | Strong build, no traction yet |
| 2 | Brand Review | 84 | Coherent, professional identity; rare at this scale |
| 3 | User Experience | 78 | Clear paths; repo README is long for first-timers |
| 4 | User Interface | 82 | Consistent, themed, responsive; verified 390–1440px |
| 5 | Content / Copy | 86 | Genuinely excellent; honest, specific, well-structured |
| 6 | SEO Audit | 74 | Site SEO solid; repo discoverability weak (no release) |
| 7 | Performance | 77 | Was 45 — CLS fix during audit lifted it materially |
| 8 | Accessibility | 88 | Was 62 — critical ARIA defect found and fixed |
| 9 | Security & Privacy | 91 | Best-in-class headers; strong app threat model |
| 10 | Technical / Bugs | 83 | 23/23 modules compile; CI can't run (billing) |
| 11 | Conversion (CRO) | 61 | **Weakest area.** No release, no demo, dead-end CTA |
| 12 | AI Opportunities | 58 | Largely untapped; several cheap high-value wins |
| 13 | Competitive Positioning | 76 | Above average on engineering, behind on proof |
| 14 | Missing Features | 64 | No release, no screenshots, no demo place file |
| 15 | Priority Matrix | 80 | Clear, sequenced, effort-estimated |

---

## Biggest strengths

**1. Security posture is genuinely excellent** *[MEASURED]*
`linacre.site` returns a full modern header set — CSP with `frame-ancestors 'none'`,
HSTS with `preload` at 2 years, COOP/CORP, and a `Permissions-Policy` that
disables `interest-cohort`. Most commercial sites don't manage this. The game
code's threat model (session-locked DataStores, idempotent receipts,
token-bucket rate limiting) is the kind of thing that normally only appears
after a studio has been burned.

**2. The content is honest in a way that is commercially rare** *[OBSERVED]*
The project page renders "Screenshots — Coming Soon" and a *disabled*
"Play — Not Yet Available" button rather than inventing placeholders. The
manifest carries an explicit comment stating no player counts exist because
the game is unpublished. This is a trust asset, not a weakness.

**3. Architectural decisions are enforced structurally, not by discipline** *[OBSERVED]*
`CosmeticService` has no access to the economy multiplier — pay-to-win is
*unrepresentable*, not merely discouraged. `UI.tween()` collapses to an instant
set under Reduced Motion, so accessibility can't be forgotten per-call-site.
Naming these guarantees in the README is a strong signal to any evaluating dev.

**4. Tooling exceeds what most solo projects ship** *[MEASURED]*
A dependency-free balance simulator that plays the game in CI and fails builds
on progression drift is unusual at any scale. `tools/sync_site.py --check`
prevents the website from drifting from the repo.

---

## Biggest weaknesses

**1. No release, no tag, no downloadable artefact** — *Critical* *[MEASURED]*
`releases: 0`, `tags: 0`. For a **template**, this is the single biggest
conversion blocker. A developer evaluating it must clone, install Aftman, install
Rojo, and build — before seeing anything. A one-click `.rbxl` attached to a
GitHub Release removes every step. **The CI already builds this artefact and
throws it away.**

**2. Zero social proof, and the CI badge shows failing** — *Critical* *[MEASURED]*
0 stars, 0 forks, 0 watchers, 0 issues. Worse, the README's first badge is red
because GitHub Actions has no runner minutes on this account. A visitor's first
impression is a broken build on an unproven repo. The badge is *lying* — all
checks pass locally — which makes it actively harmful.

**3. Nothing is playable** — *High* *[OBSERVED]*
No screenshots, no GIF, no video, no published Roblox experience. A *game*
project with no moving images asks the visitor to take everything on faith. A
15-second loop GIF in the README would likely outperform every other change here.

**4. CRO dead-ends** — *High* *[OBSERVED]*
The project page's primary CTA is a disabled button. Correct and honest, but it
leaves the visitor with nowhere to go. There is no email capture, no "notify me
at launch", no Discord — so interested traffic is lost permanently.

---

## Highest-priority improvements

Ranked by **impact ÷ effort**. Full detail in [`Priority-Roadmap.md`](Priority-Roadmap.md).

| # | Action | Effort | Impact | Why now |
|---|---|---|---|---|
| 1 | **Cut release `v0.3.0` with the `.rbxl` attached** | 30 min | 🔴 Very high | Turns a clone-and-build into a double-click. CI already produces the file. |
| 2 | **Fix or remove the failing CI badge** | 15 min | 🔴 Very high | A red badge on an unknown repo reads as abandoned. Enable Actions billing, or swap for a self-hosted status badge. |
| 3 | **Add a 15s gameplay GIF to the README** | 1 h | 🔴 Very high | The single highest-converting asset a game repo can have. |
| 4 | **Deploy the pending CLS + a11y fixes** | 5 min | 🟠 High | Already committed; needs `vercel deploy --prod`. CLS 0.42 → 0.05 is a ranking factor. |
| 5 | **Add "notify me / star for updates" capture** | 2 h | 🟠 High | Currently 100% of interested traffic is lost at the disabled CTA. |
| 6 | **Publish an unlisted Roblox place** | 3 h | 🟠 High | Converts "trust me" into "try it". Unlocks the real Play button. |
| 7 | **Post to DevForum + r/robloxgamedev** | 2 h | 🟠 High | Zero stars is a distribution problem, not a quality problem. |

---

## Effort vs business impact

```
IMPACT
  ▲
  │  [1] Release+rbxl        [3] Gameplay GIF
H │  [2] Fix CI badge        [6] Unlisted place
I │  [4] Deploy CWV fixes    [7] DevForum post
G │  [5] Lead capture
H │
  ├─────────────────────────────────────────────
M │  [8] Screenshots          [11] Seasonal content
E │  [9] JSON-LD SoftwareApp  [12] AI setup assistant
D │  [10] Repo social image
  ├─────────────────────────────────────────────
L │  [13] Wiki                [15] i18n
O │  [14] Discussions seeding [16] Video walkthrough
W │
  └─────────────────────────────────────────────►
     LOW            MEDIUM              HIGH   EFFORT
```

**The pattern:** every top-priority item is low-effort. This project's problem
isn't that hard things remain undone — it's that **cheap distribution work
hasn't been done at all**. Roughly 6 hours of focused effort addresses items
1–7 and would plausibly move the overall score from 72 to the mid-80s.

---

## Fixes already applied during this audit

I found and fixed four defects while auditing, rather than only listing them:

| Defect | Before | After | Verified by |
|---|---|---|---|
| `aria-required-parent` on tabs (WCAG 4.1.2, critical) | 1 violation | **0 violations** | axe-core |
| Site-wide CLS (footer collapse on hydration) | **0.4219** POOR | **0.0463** GOOD | CDP layout-shift observer |
| Community health profile | 71% | **100%** | GitHub API |
| Repo `homepage` pointing at itself | self-referential | → project page | GitHub API |

> The CLS bug affected **every page on linacre.site**, not just `/games`. Root
> cause: the app shell uses `flex justify-between` while the lazy-route Suspense
> fallback was ~145px tall, so the footer painted high and dropped ~342px on
> hydration. Reserving `min-h-[70svh]` on the fallback fixed it site-wide.

⚠️ **These are committed but not deployed.** Someone with Vercel credentials
must run `vercel deploy --prod` for the live site to reflect them.
