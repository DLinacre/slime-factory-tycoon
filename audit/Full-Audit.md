# Full Audit — Slime Factory Tycoon

**Surfaces:** **A** = `github.com/LIN4CRE/slime-factory-tycoon` · **B** = `linacre.site/games`
Every finding is tagged **[MEASURED]**, **[OBSERVED]**, or **[JUDGEMENT]**.

---

## 1. Executive Summary — **72 / 100**

Covered in [`Executive-Summary.md`](Executive-Summary.md). In short: engineering
and documentation are strong; distribution and proof are absent.

**Observation [MEASURED]** — Repo created `2026-07-30T17:57Z`, audited the same
day. 0 stars, 0 forks, 0 releases, 0 issues.
**Judgement** — Traction cannot be assessed on an hours-old repo. Scores reflect
*readiness to attract* traction, not traction itself.

---

## 2. Brand Review — **84 / 100**

### Observations

- **[OBSERVED]** A complete identity exists: logo, 4-size icon set, banner, and
  a 200-line `BRAND.md` covering palette, typography, motion, accessibility and
  voice. This is unusual for a solo open-source project.
- **[OBSERVED]** Colour semantics are *defined and enforced*: green = income,
  amber = value/premium, violet = world, red = locked/error. `BRAND.md` states
  "Never use green for a warning."
- **[OBSERVED]** Single source of truth: `src/shared/Theme.luau` is mirrored into
  `game.manifest.json`, and `tools/sync_site.py --check` fails CI if the website
  drifts from it. Brand consistency is *mechanically enforced*, not aspirational.
- **[OBSERVED]** The icon follows platform best practice — one character, one
  focal point, no text, readable at 128px.
- **[OBSERVED]** Voice guidance explicitly rejects manipulative copy, with
  worked examples ("You earned 2.4M Goo while away" vs "OMG!!! INSANE REWARDS").

### Weaknesses

- **[MEASURED]** No custom GitHub social preview image is set
  (`open_graph_image_url` is null), so shared repo links get GitHub's generic
  auto-card instead of the banner that already exists.
- **[JUDGEMENT]** The name is descriptive but not distinctive — "Slime",
  "Factory" and "Tycoon" are each heavily used on Roblox. Search visibility will
  suffer against established titles.
- **[JUDGEMENT]** No mascot name. The slime character is strong enough to carry
  one, and named mascots travel better socially.

### Recommendations

1. **Set the repo social preview** to `assets/banner.png` (Settings → Social
   preview). 2 minutes, improves every shared link permanently.
2. **Name the slime.** A one-word name used consistently in UI, README and
   marketing gives the brand a handle people can repeat.
3. **Add brand swatches to `BRAND.md`** as inline colour chips so the palette is
   visible without opening a colour picker.

---

## 3. User Experience — **78 / 100**

### Surface A — Repository

- **[MEASURED]** README is 14,420 bytes / 287 lines / 1,984 words with 16 `##`
  sections, 7 images, 6 badges.
- **[JUDGEMENT]** That's thorough but **long for a first-time visitor**. The
  "what is this and can I use it" decision happens in ~10 seconds, and the
  Quick Start currently sits below a strategy preamble.
- **[OBSERVED]** Strong: an "Adding content" table showing every content type is
  a single data row. This answers the key evaluation question — *how expensive
  is it to extend?* — better than prose could.
- **[OBSERVED]** Documentation is well-partitioned across STRATEGY / SETUP /
  SECURITY / OPTIMISATION / LAUNCH / BRAND rather than one wall of text.
- **[MEASURED]** 0 broken relative links across all 8 markdown files.

### Surface B — Project page

- **[OBSERVED]** Clear hierarchy: banner → identity → description → device
  support → metrics → screenshots → tabs → links.
- **[OBSERVED]** Tabbed disclosure (Features / Systems / Changelog / Roadmap)
  keeps depth available without overwhelming the initial view.
- **[MEASURED]** Verified rendering at 390px and 1440px; layout reflows cleanly,
  no horizontal scroll, no clipped text.
- **[OBSERVED]** Status is communicated three separate ways — badge, detail
  line, and disabled CTA — so the "not yet playable" state is unmissable.

### Friction points

| Issue | Surface | Severity |
|---|---|---|
| No release means evaluation requires a full toolchain install | A | **High** |
| Failing CI badge is the first thing a visitor sees | A | **High** |
| Quick Start is below the fold | A | Medium |
| Primary CTA is disabled with no alternative action | B | **High** |
| No visual proof of the game running | Both | **High** |

### Recommendations

1. Move **Quick Start above the strategy narrative** in the README.
2. Add a **60-second evaluation block** at the very top: what it is, who it's
   for, how to try it, in under 50 words.
3. Give the disabled CTA **somewhere to go** — "Star for launch updates" or
   "Watch releases" as a secondary action.

---

## 4. User Interface — **82 / 100**

### Observations

- **[MEASURED]** axe-core reports **0 violations** on `/games` after the tab fix
  (24 passing checks, desktop and mobile).
- **[OBSERVED]** The showcase reuses the host site's existing design tokens
  (`amber-color`, `border-color`, `muted`) rather than importing a second design
  system — visually consistent with the rest of linacre.site.
- **[OBSERVED]** In-game UI has a proper component library (`UI.luau`) with
  themed primitives, a 44px minimum touch target enforced in `UI.button`, and
  motion tokens.
- **[OBSERVED]** Rarity is communicated by **border colour *and* a text label**,
  so it survives colour-blindness — a detail most games miss.
- **[MEASURED]** WebP delivery with PNG fallback via `<picture>`: banner
  1,373KB → 97KB (93% reduction).

### Weaknesses

- **[MEASURED]** Mobile-only contrast failure on `button[aria-label="Open more
  navigation"] > span` — pre-existing site chrome, not the showcase.
- **[MEASURED]** `#btn-chatbot-toggle` fails WCAG 2.2 target-size (24px minimum)
  on mobile — pre-existing.
- **[JUDGEMENT]** The stat cards (23 modules / 3,724 lines / 16 achievements /
  15 cosmetics) are honest but *developer-oriented*. A player-facing visitor has
  no use for "lines of Luau".

### Recommendations

1. **Fix the two pre-existing mobile a11y defects** — both are in shared chrome
   so the fix benefits every page. Snippets in `Accessibility/fixes.md`.
2. **Split the stat cards by audience** — keep code metrics under a "For
   developers" heading; surface gameplay facts (6 zones, 10 pets, 8h offline
   earnings) to general visitors.
3. **Add `loading="eager"` + `fetchpriority="high"`** to the banner. It's the
   LCP element and currently lazy-loaded, which delays the largest paint.

---

## 5. Content / Copy — **86 / 100**

The strongest category, and by a clear margin.

### Observations

- **[OBSERVED]** Copy is **specific rather than promotional**. "First rebirth at
  33.5 min — past the point most players quit" is a real finding with a real
  number, not marketing language.
- **[OBSERVED]** The README documents a bug the author's own tooling found and
  fixed. Publishing your own mistakes is a strong credibility signal.
- **[OBSERVED]** "Honest expectations" section states plainly that most first
  Roblox games earn very little. This is commercially counter-intuitive and
  exactly why it builds trust.
- **[OBSERVED]** Monetisation ethics are framed as **structural guarantees**
  ("`CosmeticService` has no access to the economy multiplier… pay-to-win isn't
  discouraged, it's *unrepresentable*") rather than promises.
- **[OBSERVED]** No spelling or grammar defects found across 8 documents.
- **[OBSERVED]** Consistent British English throughout, matching the author's
  location.

### Weaknesses

- **[JUDGEMENT]** No single-sentence elevator pitch. The description runs 3
  lines before saying what the thing *is*.
- **[OBSERVED]** No CHANGELOG.md at repo root — release history lives only in
  `game.manifest.json`, where developers won't look.
- **[OBSERVED]** No FAQ. Predictable questions ("Can I sell a game made with
  this?", "Does MIT require credit?", "Will this get me moderated?") are
  unanswered.

### Recommendations

1. **Add a one-line pitch** under the H1: *"A complete, working Roblox idle
   tycoon you can publish — with the security and save-integrity work already
   done."*
2. **Create `CHANGELOG.md`** at root, generated from the manifest so it can't
   drift.
3. **Add an FAQ** to the README covering licensing, monetisation rights, and
   Roblox policy compliance.

---

## 6. SEO Audit — **74 / 100**

### Surface B — technical signals [MEASURED]

| Signal | Status |
|---|---|
| `robots.txt` | ✅ Present, well-formed, sitemap declared |
| `sitemap.xml` | ✅ 19 URLs, `/games` included with `lastmod` |
| Canonical | ✅ `https://www.linacre.site/games` |
| `<title>` | ✅ 78 chars, keyword-led, brand-suffixed |
| Meta description | ✅ 218 chars — **slightly over the ~160 display limit** |
| OG image | ✅ Points at the banner |
| `twitter:card` | ✅ `summary_large_image` |
| Prerendering | ✅ 22 static routes; content is crawlable without JS |
| Schema | ⚠️ `VideoGame` present; `SoftwareSourceCode` + `BreadcrumbList` missing |
| Image alt text | ✅ Descriptive on all showcase images |
| HTTPS + HSTS | ✅ `max-age=63072000; includeSubDomains; preload` |

### Surface A — repo discoverability

- **[MEASURED]** 20 topics set — at GitHub's cap, well-chosen, covering
  `roblox`, `luau`, `rojo`, `idle-game`, `monetization`, `anti-cheat`.
- **[MEASURED]** **0 releases.** GitHub weights releases heavily in repo search,
  and release pages are separately indexable. This is the biggest single SEO
  miss on this surface.
- **[MEASURED]** `homepage` previously pointed at the repo itself — ✅ fixed
  during audit, now points to the project page.
- **[MEASURED]** No GitHub Pages site (`has_pages: false`), so there's no
  indexable documentation surface beyond the README.

### Keyword opportunities [JUDGEMENT]

| Term | Intent | Current coverage |
|---|---|---|
| "roblox tycoon template" | High commercial | Weak — no release page |
| "roblox datastore session locking" | High technical | **Strong content, zero visibility** |
| "roblox anti exploit remoteevent" | High technical | Strong content, buried in SECURITY.md |
| "roblox idle game source code" | High commercial | Weak |
| "rojo project template" | Medium | Weak |

**Judgement** — `SECURITY.md` and `OPTIMISATION.md` contain genuinely
search-worthy technical content that is currently invisible because it only
exists inside a repo with no inbound links. Publishing these as pages on
linacre.site would target real developer queries.

### Prioritised fixes

1. **Cut a GitHub Release** — highest SEO impact available on Surface A.
2. **Trim meta description to ≤160 chars** — prevents SERP truncation.
3. **Add `SoftwareSourceCode` + `BreadcrumbList` JSON-LD** — files ready in
   `Schema/`.
4. **Enable GitHub Pages** on `/docs` to create indexable documentation.
5. **Republish SECURITY.md as a linacre.site article** targeting the DataStore
   and anti-exploit queries.

---

## 7. Performance — **77 / 100** *(was 45 before the audit's fix)*

All figures are **lab data**, mobile viewport (390×844), unthrottled. Field
data will be worse. No CrUX record exists (insufficient traffic).

### Measured — before fix

| Metric | Value | Threshold | Verdict |
|---|---:|---|---|
| TTFB | 196 ms | <800 ms | ✅ Good |
| FCP | 412 ms | <1,800 ms | ✅ Good |
| LCP | 1,036 ms | <2,500 ms | ✅ Good |
| **CLS** | **0.4219** | <0.10 | 🔴 **POOR** |
| Requests | 21 | — | ✅ Lean |
| Transfer | 238 KB | — | ✅ Lean |

### Root cause [MEASURED]

CLS was **identical (0.4219) on `/`, `/projects`, `/games` and `/about`** —
proving a shared-shell defect, not a page-specific one.

Layout-shift attribution:

```
[432ms] 0.0155  CANVAS.cursor-grab
[791ms] 0.4064  FOOTER.w-full  y,h: 502,342 -> 0,0    ← 96% of total CLS
```

The app shell uses `flex flex-col justify-between`, while the lazy-route
Suspense fallback was only ~145px tall. The footer therefore painted high in the
viewport and dropped ~342px once the route chunk resolved.

### After fix [MEASURED]

Reserved `min-h-[70svh]` on the route fallback; took the prerender SEO shell out
of layout flow.

| Route | Viewport | Before | After | Verdict |
|---|---|---:|---:|---|
| `/games` | 390px | 0.4219 | **0.0463** | ✅ GOOD |
| `/projects` | 390px | 0.4219 | **0.0463** | ✅ GOOD |
| `/games` | 1440px | 0.4219 | **0.0145** | ✅ GOOD |
| `/` | 390px | 0.4219 | **0.1434** | ⚠️ Improved, still over |

### Remaining opportunities

- **[MEASURED]** 100 KB of fonts across three variable families (Inter 47KB,
  JetBrains Mono 31KB, Space Grotesk 22KB) — 42% of total page weight.
  **Recommendation:** subset to `latin` only and preload just the one used
  above the fold.
- **[OBSERVED]** The banner is the LCP element but is `loading="lazy"`.
  **Recommendation:** `loading="eager"` + `fetchpriority="high"`.
- **[MEASURED]** `/` still at 0.1434 — needs the same treatment applied to
  whatever its largest late-loading component is.
- **[OBSERVED]** `cache-control: public, max-age=0, must-revalidate` on HTML is
  correct for a prerendered SPA; hashed assets are immutable. No change needed.

---

## 8. Accessibility — **88 / 100** *(was 62 before the audit's fix)*

Tested with axe-core (WCAG 2.0/2.1/2.2 A + AA) at 1440×900 and 390×844.

### Critical defect found — in my own component

```
[critical] aria-required-parent (x4)
  → role="tab" elements without a role="tablist" parent
  WCAG 4.1.2 Name, Role, Value
```

The tab buttons carried `aria-selected` and `role="tab"` but had no `tablist`
container. Screen readers would announce them as orphaned tabs with no group
context, and there was **no keyboard navigation** between them (WCAG 2.1.1).

### Fix applied

- Added `role="tablist"` with `aria-label`
- Wired `aria-controls` ↔ `aria-labelledby` between each tab and its panel
- Roving `tabIndex` (0 on active, −1 on inactive) per ARIA authoring practice
- `ArrowLeft` / `ArrowRight` keyboard navigation with focus management
- Visible `focus-visible` rings, 44px minimum target height
- `aria-controls` on the changelog accordion
- `prefers-reduced-motion` honoured via `useReducedMotion()`

### Verified after [MEASURED]

```
VIOLATIONS: 0
ArrowRight -> sft-tab-systems
ArrowRight -> sft-tab-changelog
tabpanel visible: true
```

### Remaining (pre-existing site chrome, not the showcase)

| Issue | Impact | WCAG |
|---|---|---|
| `button[aria-label="Open more navigation"] > span` contrast | Serious | 1.4.3 |
| `#btn-chatbot-toggle` below 24px target | Serious | 2.5.8 (WCAG 2.2) |

### In-game accessibility [OBSERVED]

Genuinely above standard for a Roblox project — Reduced Motion, High Contrast,
80–150% text scale, and three colour-blind modes, all persisted **server-side**
so they follow the player across devices. `UI.tween()` collapsing to an instant
set under Reduced Motion means the setting can't be forgotten per-call-site.

**Not deducted but worth noting:** these are unverifiable without Roblox Studio.
Scored on code inspection only.

---

## 9. Security & Privacy — **91 / 100**

Highest-scoring category.

### Measured headers on `linacre.site`

| Header | Value | Verdict |
|---|---|---|
| `content-security-policy` | `default-src 'self'`, `object-src 'none'`, `frame-ancestors 'none'`, `base-uri 'self'`, `form-action 'self'`, `upgrade-insecure-requests` | ✅ Strong |
| `strict-transport-security` | `max-age=63072000; includeSubDomains; preload` | ✅ 2yr + preload |
| `x-frame-options` | `DENY` | ✅ |
| `x-content-type-options` | `nosniff` | ✅ |
| `referrer-policy` | `strict-origin-when-cross-origin` | ✅ |
| `permissions-policy` | camera, mic, geo, payment, USB, sensors, `interest-cohort` all `()` | ✅ Excellent |
| `cross-origin-opener-policy` | `same-origin` | ✅ |
| `cross-origin-resource-policy` | `same-origin` | ✅ |

**Judgement** — This exceeds what most commercial sites ship. `interest-cohort=()`
opting out of FLoC is a privacy detail almost nobody bothers with.

### Application threat model [OBSERVED]

The game code assumes a **fully compromised client** and is built accordingly:

- Client sends *intent* ("I tapped N times"), never *value*
- Token-bucket click limiting: 20/s sustained, hard clamp of 100/call
- Declarative per-remote validators rejecting NaN, ±infinity, type confusion,
  oversized strings
- Session-locked DataStores via atomic `UpdateAsync` — prevents cross-server dupes
- Idempotent `ProcessReceipt` keyed by `PurchaseId`, save-before-confirm with
  rollback
- Never saves on a failed load — the classic cause of "I lost everything"

**[JUDGEMENT]** The decision to *cap* rewards rather than ban on detection is
correct and better-reasoned than most anti-cheat writing. Banning on heuristics
punishes lagging players; capping costs the exploiter everything and the honest
player nothing.

### Weaknesses

- **[MEASURED]** CSP allows `style-src 'unsafe-inline'`. Common with CSS-in-JS
  but it's the one weak directive. **Recommendation:** move to nonce-based
  styles when practical.
- **[MEASURED]** No `Content-Security-Policy-Report-Only` endpoint, so
  violations in the wild go unseen.
- **[OBSERVED]** No `.github/dependabot.yml` — npm dependencies aren't
  automatically monitored.
- **[OBSERVED]** No `SECURITY.md` at audit start — ✅ added during audit.

---

## 10. Technical / Bugs — **83 / 100**

### Measured

- **23/23 Luau modules compile** under the official `luau-compile` toolchain.
- **0 broken relative links** across 8 markdown documents.
- **0 TypeScript errors** after fixing a pre-existing one.
- Repo: 52 files, 4,281 KB.

### Bugs found and fixed during this audit

| # | Bug | Severity | Status |
|---|---|---|---|
| 1 | `role="tab"` without `tablist` parent | **Critical** | ✅ Fixed |
| 2 | Site-wide CLS 0.4219 from footer collapse | **High** | ✅ Fixed |
| 3 | `setIsPaletteOpen` undefined in `App.tsx` — broke `npm run build` | **High** | ✅ Fixed (pre-existing on `main`) |
| 4 | Repo `homepage` self-referential | Medium | ✅ Fixed |
| 5 | Luau type annotations on table-field assignment (2 files) | **High** | ✅ Fixed earlier in session |

> Bug 5 is worth noting: it was caught only after replacing a regex-based syntax
> heuristic with the **real Luau compiler**. The heuristic produced false
> positives *and* missed genuine errors that would have prevented the modules
> loading in Studio. Lesson: use the real parser.

### Outstanding issues

| # | Issue | Severity | Guidance |
|---|---|---|---|
| 1 | **CI cannot execute** — all jobs finish with 0 steps and empty logs | **High** | Actions billing/entitlement on the account. Enable it, or move to a self-hosted status badge. The red badge is worse than no badge. |
| 2 | Large PNGs committed (1.4MB icon, 1.3MB banner) | Medium | Every clone pays for these. Use Git LFS, or keep only WebP + a single high-res master. |
| 3 | `assets/` served from repo, not a CDN | Low | Fine at this scale. |
| 4 | No dependency scanning | Medium | Add `dependabot.yml`. |
| 5 | Game code unverified at runtime | Medium | No Studio in this environment — syntax-verified only. Needs a manual play-test pass. |

### Maintainability [JUDGEMENT]

Above average. Auto-discovered services with an explicit lifecycle mean adding a
system requires no bootstrap edit. All tunable values live in `GameConfig` /
`Content`. Comments consistently explain *why* rather than *what*. The
`--check` modes on `sync_site.py` and `balance_sim.py` turn conventions into
enforced gates.

---

## 11. Conversion (CRO) — **61 / 100**

The weakest category and the largest opportunity.

### Funnel as it exists today

```
Discovery ──► Repo/page ──► Evaluate ──► Try ──► Adopt ──► Contribute
   ✗ none        ✓ good       ⚠ heavy    ✗ blocked  ⚠ hard    ⚠ no path
```

### Observations

- **[MEASURED]** 0 stars, 0 forks, 0 watchers. No social proof of any kind.
- **[MEASURED]** 0 releases — trying the template requires: clone → install
  Aftman → install Rojo → build → open Studio. **Five steps before seeing
  anything.**
- **[OBSERVED]** The project page's primary CTA is a *disabled* button. Honest,
  but it's a dead end with no secondary action.
- **[OBSERVED]** No email capture, no Discord, no "notify me at launch". Every
  interested visitor is lost permanently.
- **[OBSERVED]** No screenshots, GIF, or video of a *game* project.
- **[MEASURED]** The README's first badge is **red**. On an unknown repo, a
  failing build reads as abandoned.

### The single highest-value fix

**Cut a GitHub Release with the built `.rbxl` attached.**

The CI workflow *already builds this artefact* (`rojo build` → upload-artifact)
and then discards it. Attaching it to a release turns a five-step evaluation
into a double-click. Effort: ~30 minutes. Impact: removes the largest barrier
in the funnel.

### Recommendations, ranked

| # | Action | Effort | Expected effect |
|---|---|---|---|
| 1 | Release with `.rbxl` attached | 30 m | Removes the biggest adoption barrier |
| 2 | Fix or remove the red CI badge | 15 m | Removes an active trust deterrent |
| 3 | 15-second gameplay GIF in README | 1 h | Highest-converting asset for a game repo |
| 4 | "⭐ Star for launch updates" as the disabled CTA's partner | 30 m | Captures currently-lost intent |
| 5 | Unlisted Roblox place link | 3 h | Converts "trust me" to "try it" |
| 6 | Seed 3–5 GitHub Discussions | 1 h | An empty community looks dead; a seeded one looks new |
| 7 | DevForum + r/robloxgamedev post | 2 h | Zero stars is a distribution problem |

---

## 12. AI Opportunities — **58 / 100**

Largely untapped. Scored on *opportunity captured*, not opportunity available.

### Already present [OBSERVED]

- The balance simulator is algorithmic modelling, not ML, but it fills the same
  role: automated judgement in CI. Genuinely novel for this niche.
- `sync_site.py` automates cross-repo consistency.

### Opportunities, by value

| # | Opportunity | Effort | Est. value | Notes |
|---|---|---|---|---|
| 1 | **AI setup assistant in the README** — a prompt block a developer pastes into any LLM with the repo context to get personalised setup help | 1 h | **High** | Near-zero cost; directly reduces the biggest adoption barrier |
| 2 | **LLM-generated release notes** from commit messages | 2 h | Medium | Commits are already detailed enough to make this trivial |
| 3 | **Balance-tuning copilot** — feed simulator output to an LLM for suggested `GameConfig` adjustments | 1 d | **High** | The simulator already produces structured output; this closes the loop |
| 4 | **Issue triage bot** — auto-label by area using the existing issue-form dropdown | 3 h | Medium | Cheap once issues exist |
| 5 | **AI-assisted playtest summariser** — parse Studio logs into a session report | 2 d | Medium | Valuable once real playtests happen |
| 6 | **In-game AI tutorial hints** — contextual help when a player stalls | 3 d | Low–Medium | Cost per player is a real concern at Roblox scale; the simulator already identifies stall points more cheaply |
| 7 | **Automated changelog → social posts** | 3 h | Medium | Supports the "ship every Friday" strategy the docs advocate |

**Judgement** — #1 and #3 are the standouts. #1 because it's an hour of work
against the project's biggest funnel leak; #3 because the simulator already
emits exactly the structured data an LLM would need.

**Recommend skipping** #6 for now. Per-player inference costs scale badly on
Roblox, and the docs' own stated bar ("skip anything that won't significantly
improve retention, engagement or revenue") argues against it.

---

## 13. Competitive Positioning — **76 / 100**

Compared against **documented best practice** for open-source game templates. No
competitor statistics are invented; only observable norms are referenced.

### Above average

| Area | Why |
|---|---|
| **Security engineering** | Session locking + idempotent receipts + declarative validation is rare in *published* Roblox games, let alone free templates. |
| **Automated balance testing** | I'm not aware of another Roblox template that simulates progression in CI. |
| **Documentation depth** | 8 documents covering strategy, setup, security, optimisation, launch and brand. Most templates ship a README. |
| **Honest communication** | Publishing your own bug, and refusing to fake screenshots, is genuinely uncommon. |
| **Accessibility** | Server-persisted reduced motion, contrast, text scale and colour-blind modes exceed typical Roblox practice. |

### Average

| Area | Notes |
|---|---|
| Code architecture | Service registry + DI is standard in mature Roblox codebases (Knit, Matter). Well-executed, not novel. |
| Rojo tooling | Expected baseline for a serious template. |
| Licensing | MIT is the norm. |

### Behind

| Area | Gap |
|---|---|
| **Distribution** | 0 stars, 0 releases, no marketplace presence, no community posts. Established templates have hundreds to thousands of stars. |
| **Proof of function** | No screenshots, video, or playable link. Competitors typically lead with a demo. |
| **Community infrastructure** | Discussions only just enabled, no Discord, no contributor base. |
| **Versioning** | No releases or tags means no semver story and no upgrade path for adopters. |

### Patterns worth adopting

1. **Lead with a GIF.** The convention in successful game-dev repos is a moving
   image within the first screen.
2. **Ship a demo place.** Roblox templates that succeed link an unlisted
   experience so evaluation costs nothing.
3. **Semantic versioning with release notes.** Adopters need to know what breaks.
4. **A "Built with this" showcase section** — even empty with an invitation,
   it signals the project expects real use.

---

## 14. Missing Features — **64 / 100**

Prioritised by business value.

### Critical

| Missing | Value | Effort |
|---|---|---|
| **GitHub Release + `.rbxl` artefact** | Removes the largest adoption barrier | 30 m |
| **Working CI status** (or badge removal) | Red badge actively deters | 15 m |
| **Visual proof** — GIF or screenshots | A game with no images asks for blind faith | 1–2 h |

### High

| Missing | Value | Effort |
|---|---|---|
| **Playable demo** (unlisted Roblox place) | Converts trust into trial | 3 h |
| **Lead capture** on the disabled CTA | Currently 100% of intent is lost | 2 h |
| **`CHANGELOG.md`** at root | Developers look here, not in a manifest | 1 h |
| **`dependabot.yml`** | Unmonitored npm dependencies | 15 m |
| **FAQ** — licensing, monetisation rights, moderation | Removes purchase-equivalent hesitation | 1 h |

### Medium

| Missing | Value | Effort |
|---|---|---|
| GitHub Pages documentation site | Indexable surface for technical queries | 4 h |
| Repo social preview image | Every shared link is currently generic | 5 m |
| `SoftwareSourceCode` + `BreadcrumbList` JSON-LD | Rich results | 30 m |
| Seasonal event content | Framework exists, no season declared | 4 h |
| Analytics instrumentation (`AnalyticsService`) | Post-launch decisions need data | 3 h |

### Low

Accessibility statement page · i18n · video walkthrough · Discord ·
contributor recognition · `.editorconfig` for the site repo

---

## 15. Priority Matrix — **80 / 100**

Full sequencing in [`Priority-Roadmap.md`](Priority-Roadmap.md); tasks in
[`Developer-Tasks.md`](Developer-Tasks.md).

| Priority | Count | Total effort | Theme |
|---|---:|---|---|
| 🔴 Critical | 4 | ~2 h | Release, CI badge, deploy pending fixes, visual proof |
| 🟠 High | 7 | ~12 h | Demo place, lead capture, distribution, changelog, a11y remnants |
| 🟡 Medium | 9 | ~20 h | Docs site, schema, fonts, analytics, seasonal content |
| 🟢 Low | 8 | ~30 h | i18n, video, Discord, accessibility statement |

**The defining insight:** all four Critical items total roughly **two hours**.
This project is not blocked by hard engineering — it's blocked by cheap
distribution work that hasn't been started.
