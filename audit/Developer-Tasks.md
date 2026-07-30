# Developer Tasks — GitHub Issues format

Copy each block directly into a GitHub issue. Ordered by priority.

---

## 🔴 CRITICAL

---

### T-01 · Cut release v0.3.0 with the built `.rbxl` attached

**Description**
The CI workflow already builds a place file via `rojo build` and uploads it as a
workflow artifact — then discards it. No GitHub Release exists, so evaluating
this template requires clone → install Aftman → install Rojo → build → open
Studio. Five steps before seeing anything.

Attaching the artefact to a release turns evaluation into a double-click. This
is the single largest conversion barrier in the project.

**Acceptance criteria**
- [ ] `rojo build default.project.json --output SlimeFactoryTycoon-v0.3.0.rbxlx` succeeds
- [ ] Release `v0.3.0` published with the `.rbxlx` attached
- [ ] Release notes use `Content/release-notes-v0.3.0.md`
- [ ] Known limitations (CI badge, placeholder asset IDs) stated honestly in the notes
- [ ] README links to `/releases/latest` above the fold
- [ ] Downloading and opening the file in Studio produces a running game

**Priority:** Critical · **Effort:** 30 min · **Owner:** eng

---

### T-02 · Resolve the failing CI badge

**Description**
The README's first badge is red. All three CI jobs complete with **zero steps
executed** and empty logs — an Actions billing/entitlement issue on the account,
not a code defect. Every check passes locally via `./tools/verify.sh`.

A badge that reports failure when the code is fine is worse than no badge. On an
unknown repository it reads as abandoned.

**Acceptance criteria**
- [ ] One of: (a) Actions billing enabled and badge green; (b) badge replaced
      with an honest static one; (c) badge removed
- [ ] If (b) or (c), README explains how to verify locally
- [ ] No badge in the README reports a state that isn't true

**Priority:** Critical · **Effort:** 15 min · **Owner:** eng

---

### T-03 · Deploy the pending CLS and accessibility fixes

**Description**
Two fixes are committed to `linacre.site@main` but not deployed:
- CLS 0.4219 → 0.0463 (site-wide footer collapse on hydration)
- Critical `aria-required-parent` WCAG violation on the showcase tabs

CLS above 0.25 is a documented ranking signal, and the ARIA issue is a Level A
failure. Both are live-affecting until deployed.

**Acceptance criteria**
- [ ] `vercel deploy --prod --yes --project linacre-site-repo` run
- [ ] Live CLS on `/games` measures below 0.10
- [ ] Live axe-core scan reports 0 violations on the showcase
- [ ] Verified on both 390px and 1440px viewports

**Priority:** Critical · **Effort:** 5 min (blocked on Vercel credentials) · **Owner:** eng

---

### T-04 · Set the repository social preview image

**Description**
`open_graph_image_url` is null, so every shared repo link renders GitHub's
generic auto-card instead of the banner that already exists in `assets/`.

**Acceptance criteria**
- [ ] Settings → General → Social preview → `assets/banner.png` uploaded
- [ ] Verified via a link preview debugger

**Priority:** Critical · **Effort:** 5 min · **Owner:** design

---

## 🟠 HIGH

---

### T-05 · Record and embed a 15-second gameplay GIF

**Description**
This is a *game* project with no moving images anywhere. A short loop is the
highest-converting asset a game repository can have, and its absence asks every
visitor to take the entire README on faith.

**Acceptance criteria**
- [ ] 10–15s loop: tap the vat → numbers climb → buy upgrade → rebirth flash
- [ ] Under 5MB, 30fps, ≤800px wide
- [ ] Placed directly beneath the README H1
- [ ] Also added to the project page gallery
- [ ] Descriptive alt text

**Priority:** High · **Effort:** 1–2 h · **Owner:** design

---

### T-06 · Publish an unlisted Roblox place and enable the Play CTA

**Description**
The project page's primary CTA is a disabled "Not Yet Available" button. The
honesty is correct, but it's a dead end. An unlisted place converts "trust me"
into "try it".

The showcase component already handles this: setting `links.roblox` in the
manifest automatically switches the disabled state to a live CTA. No component
change required.

**Acceptance criteria**
- [ ] Place published as unlisted with the icon from `assets/icon-512.png`
- [ ] `links.roblox` set in `game.manifest.json`
- [ ] `python3 tools/sync_site.py --site ../linacre.site` run
- [ ] Live Play button appears and works
- [ ] `status` / `statusDetail` updated to reflect playability

**Priority:** High · **Effort:** 3 h · **Owner:** eng

---

### T-07 · Add lead capture beside the disabled CTA

**Description**
100% of interested traffic currently hits a dead end. Even without email
infrastructure, a "Star for launch updates" action captures intent that is
otherwise lost permanently.

**Acceptance criteria**
- [ ] Secondary action rendered next to the disabled Play button
- [ ] Links to the repo with `?utm_source=linacre_games` for attribution
- [ ] Keyboard accessible, 44px minimum target
- [ ] Does not weaken the honest "Not Yet Available" state

**Priority:** High · **Effort:** 2 h · **Owner:** eng + growth

---

### T-08 · Capture and publish real screenshots

**Description**
`manifest.screenshots` is empty, so the gallery honestly renders "Coming Soon".
Populating the array makes the gallery render automatically.

**Acceptance criteria**
- [ ] 4–6 screenshots: main loop, upgrades, pet hatch, rebirth, achievements
- [ ] Both mobile and desktop aspect ratios
- [ ] WebP with PNG fallback, under 150KB each
- [ ] Added to `manifest.screenshots` and synced
- [ ] Descriptive alt text on each

**Priority:** High · **Effort:** 1 h · **Owner:** design

---

### T-09 · Post to DevForum and r/robloxgamedev

**Description**
Zero stars is a distribution problem, not a quality problem. Lead with the two
genuinely novel things — the CI balance simulator and the session-locking
write-up — rather than "I made a template", which reads as noise.

**Acceptance criteria**
- [ ] DevForum #resources:community-resources post
- [ ] r/robloxgamedev post
- [ ] Both lead with the technical hook, not the template pitch
- [ ] Include the GIF and a direct release link
- [ ] Author available to answer replies for 48h

**Priority:** High · **Effort:** 2 h · **Owner:** growth

---

### T-10 · Add CHANGELOG.md and dependabot.yml

**Description**
Developers look for a changelog at repo root, not inside a JSON manifest.
Separately, npm dependencies are entirely unmonitored.

**Acceptance criteria**
- [ ] `CHANGELOG.md` at root following Keep a Changelog
- [ ] Generated from `game.manifest.json` so it can't drift
- [ ] `.github/dependabot.yml` for npm + github-actions
- [ ] Minor/patch updates grouped to avoid PR spam

**Priority:** High · **Effort:** 1.5 h · **Owner:** eng

---

### T-11 · Fix the two remaining mobile accessibility defects

**Description**
axe-core reports two serious issues in shared site chrome (not the showcase), so
fixing them benefits every page:
- `button[aria-label="Open more navigation"] > span` — contrast below 4.5:1 (WCAG 1.4.3)
- `#btn-chatbot-toggle` — below the 24px minimum target (WCAG 2.5.8)

**Acceptance criteria**
- [ ] Contrast measured at ≥4.5:1
- [ ] Chatbot toggle ≥44×44px
- [ ] axe-core reports 0 serious violations at 390px
- [ ] No visual regression on desktop

**Priority:** High · **Effort:** 1 h · **Owner:** eng + design

---

## 🟡 MEDIUM

---

### T-12 · Trim meta description and add preload hints

**Description**
The `/games` description is 218 chars and will be truncated. Separately, the
banner is the LCP element but is lazy-loaded, delaying the largest paint.

**Acceptance criteria**
- [ ] Meta description ≤160 chars
- [ ] Banner uses `loading="eager"` + `fetchpriority="high"`
- [ ] `<link rel="preload">` for the banner and the above-the-fold font
- [ ] LCP measured before and after

**Priority:** Medium · **Effort:** 45 min · **Owner:** eng
**Assets:** `Metadata/meta-tags.html`

---

### T-13 · Add SoftwareSourceCode and BreadcrumbList JSON-LD

**Description**
The showcase has `VideoGame` markup. Adding `SoftwareSourceCode` targets
developer-intent searches, and breadcrumbs earn an extra SERP line.

**Acceptance criteria**
- [ ] Both blocks added to `/games`
- [ ] Validates in Google's Rich Results Test with no errors
- [ ] No fabricated ratings, prices, or download counts

**Priority:** Medium · **Effort:** 30 min · **Owner:** eng
**Assets:** `Schema/software-application.jsonld`, `Schema/breadcrumb.jsonld`

---

### T-14 · Publish the technical docs as an indexable site

**Description**
`SECURITY.md` and `OPTIMISATION.md` contain genuinely search-worthy content
("roblox datastore session locking", "roblox remoteevent validation") that is
invisible because it only exists inside an unlinked repo.

**Acceptance criteria**
- [ ] GitHub Pages enabled, or the articles republished on linacre.site
- [ ] Each targets one primary query
- [ ] Canonical tags prevent duplicate-content conflicts with the repo
- [ ] Cross-linked from the README and project page

**Priority:** Medium · **Effort:** 4 h · **Owner:** content + eng

---

### T-15 · Font subsetting and preload

**Description**
100KB across three variable families is 42% of page weight.

**Acceptance criteria**
- [ ] Subset to `latin` only
- [ ] Only the above-the-fold family preloaded
- [ ] `font-display: swap` on all
- [ ] Total font weight below 60KB
- [ ] No visible FOUT regression

**Priority:** Medium · **Effort:** 2 h · **Owner:** eng

---

### T-16 · Fix remaining CLS on the homepage

**Description**
`/` still measures 0.1434 after the shell fix — improved from 0.4219 but above
the 0.10 threshold. Same technique applies: reserve height for the largest
late-mounting component.

**Acceptance criteria**
- [ ] Shift sources identified via the Layout Instability API
- [ ] `/` measures below 0.10 at 390px and 1440px
- [ ] No regression on other routes

**Priority:** Medium · **Effort:** 2 h · **Owner:** eng

---

### T-17 · Ship one seasonal event

**Description**
`Content.Seasons` is deliberately empty rather than filled with placeholder
data. Declaring one real season proves the content pipeline works end to end
and gives the project a live-update story.

**Acceptance criteria**
- [ ] One season in `Content.Seasons` with real dates
- [ ] Themed accent colour, 3 event pets, a reward track
- [ ] Season UI renders and the track progresses
- [ ] Manifest changelog updated and synced
- [ ] Balance simulator still passes

**Priority:** Medium · **Effort:** 4 h · **Owner:** eng + design

---

### T-18 · Add an AI setup assistant block to the README

**Description**
A copy-paste prompt giving any LLM enough repository context to walk a developer
through setup and troubleshooting. Near-zero cost against the project's biggest
funnel leak.

**Acceptance criteria**
- [ ] Collapsible README section with a self-contained prompt
- [ ] Covers structure, setup order, and the API Services gotcha
- [ ] Tested against at least two different models
- [ ] Explicitly notes it's a convenience, not official support

**Priority:** Medium · **Effort:** 1 h · **Owner:** content

---

### T-19 · Wire AnalyticsService funnel instrumentation

**Description**
`LAUNCH.md` tells the reader which metrics to watch, but the code doesn't emit
them. Instrument the funnel so post-launch decisions have data.

**Acceptance criteria**
- [ ] `LogFunnelStepEvent` for tutorial → first upgrade → first rebirth → first purchase
- [ ] `LogEconomyEvent` for all currency sources and sinks
- [ ] No PII logged
- [ ] Documented in `LAUNCH.md`

**Priority:** Medium · **Effort:** 3 h · **Owner:** eng

---

### T-20 · Balance-tuning copilot

**Description**
`balance_sim.py` already emits structured progression data. Feeding it to an LLM
for suggested `GameConfig` adjustments closes the loop between measurement and
tuning.

**Acceptance criteria**
- [ ] Script pipes simulator JSON to an LLM with the balance targets as context
- [ ] Outputs concrete suggested config diffs
- [ ] Suggestions are advisory only — never auto-committed
- [ ] Documented in `CONTRIBUTING.md`

**Priority:** Medium · **Effort:** 1 d · **Owner:** eng

---

## 🟢 LOW

| ID | Task | Effort | Owner |
|---|---|---|---|
| T-21 | Move large PNGs to Git LFS (4.2MB repo, every clone pays) | 1 h | eng |
| T-22 | Seed 3–5 GitHub Discussions threads | 1 h | growth |
| T-23 | "Built with this" showcase section | 2 h | content |
| T-24 | 5-minute video walkthrough | 4 h | content |
| T-25 | Accessibility statement page | 2 h | content |
| T-26 | CSP report-only endpoint | 3 h | eng |
| T-27 | Nonce-based CSP to remove `style-src 'unsafe-inline'` | 1 d | eng |
| T-28 | i18n scaffolding | 3 d | eng |

---

## Summary

| Priority | Tasks | Effort |
|---|---:|---|
| 🔴 Critical | 4 | ~1 h |
| 🟠 High | 7 | ~12 h |
| 🟡 Medium | 9 | ~20 h |
| 🟢 Low | 8 | ~30 h |
| **Total** | **28** | **~63 h** |

All four Critical tasks together take about an hour and require no new
engineering.
