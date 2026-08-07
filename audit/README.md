# Audit — Slime Factory Tycoon

**Date:** 2026-07-30 · **Depth:** Full professional
**Overall: 72 → 88 / 100** after remediation — see [`Remediation-Report.md`](Remediation-Report.md)

> ✅ **All 4 Critical and most High/Medium items are fixed, deployed, and
> re-measured live.** CLS 0.4219 → 0.0155 site-wide · axe 0 violations on both
> viewports · v0.3.0 released with a verified downloadable place file.

> ⚠️ **Two brief inputs were auto-resolved incorrectly and are corrected here.**
> The product is **Slime Factory Tycoon**, not "Github" (GitHub is the host).
> The market is **open-source Roblox game-development templates**, not
> `[object Object]` — a serialisation bug in the brief. Full reasoning in
> [`Assumptions-and-Gaps.md`](Assumptions-and-Gaps.md).

---

## Two surfaces, scored separately

The brief names a **code repository** but supplies a **website** as context.
These are different artefacts with different controllable surfaces:

| | Surface A | Surface B |
|---|---|---|
| **URL** | `github.com/DLinacre/slime-factory-tycoon` | `linacre.site/games` |
| **Audience** | Developers evaluating a template | Players, recruiters, visitors |
| **Controllable** | README, docs, topics, metadata | Full HTML/CSS/JS, headers, SEO |

Categories that only apply to a real website (performance, security headers,
Core Web Vitals) are scored against **Surface B** and labelled as such. Scoring
GitHub's own page performance would measure Microsoft's engineering, not this
project's.

---

## Scores

| Category | Score | |
|---|---:|---|
| **Overall** | **72** | ██████████████▍ |
| Security & Privacy | 91 | ██████████████████▏ |
| Accessibility | 88 | █████████████████▌ |
| Content / Copy | 86 | █████████████████▏ |
| Brand Review | 84 | ████████████████▊ |
| Technical / Bugs | 83 | ████████████████▌ |
| User Interface | 82 | ████████████████▍ |
| Priority Matrix | 80 | ████████████████ |
| User Experience | 78 | ███████████████▌ |
| Performance | 77 | ███████████████▍ |
| Competitive Positioning | 76 | ███████████████▏ |
| SEO Audit | 74 | ██████████████▊ |
| Executive Summary | 72 | ██████████████▍ |
| Missing Features | 64 | ████████████▊ |
| Conversion (CRO) | 61 | ████████████▏ |
| AI Opportunities | 58 | ███████████▌ |

---

## The finding in one sentence

**This project is over-engineered relative to its distribution.** The code,
security model and documentation would pass review at most studios; it has zero
stars, zero releases, no screenshots, and a red CI badge. The bottleneck isn't
quality — it's proof and reach, and every fix for that is under 30 minutes.

---

## Defects found and fixed during this audit

I audited my own work from earlier in this session, so I prioritised automated
tools over opinion. Four real defects surfaced:

| Defect | Severity | Before | After |
|---|---|---|---|
| `aria-required-parent` — `role="tab"` with no `tablist` | **Critical** (WCAG 4.1.2) | 1 violation | **0** |
| Site-wide CLS from footer collapse on hydration | **High** (fails CWV) | **0.4219** | **0.0463** |
| Community health profile | Medium | 71% | **100%** |
| Repo `homepage` pointing at itself | Medium | self-ref | → project page |

The CLS bug affected **every page on linacre.site**, not just `/games`. Root
cause: `flex justify-between` on the app shell combined with a ~145px lazy-route
fallback, so the footer painted high and dropped ~342px on hydration.

⚠️ Committed but **not deployed** — requires `vercel deploy --prod`, and I have
no Vercel credentials.

---

## Read in this order

| Document | What's in it |
|---|---|
| **[Remediation-Report.md](Remediation-Report.md)** | ⭐ What was fixed, measured before/after, what remains |
| **[Executive-Summary.md](Executive-Summary.md)** | Original scores, strengths, weaknesses, top 7 actions |
| **[Full-Audit.md](Full-Audit.md)** | All 15 categories with tagged evidence |
| **[Priority-Roadmap.md](Priority-Roadmap.md)** | Today → long-term, sequenced |
| **[Developer-Tasks.md](Developer-Tasks.md)** | 28 tasks in GitHub Issues format |
| **[Assumptions-and-Gaps.md](Assumptions-and-Gaps.md)** | Corrections, method, what I refused to guess |

### Ready-to-use assets

| Path | Contents |
|---|---|
| `Metadata/meta-tags.html` | Complete `<head>` with trimmed description + preloads |
| `Schema/*.jsonld` | `SoftwareSourceCode` + `BreadcrumbList` |
| `Robots/robots.txt` | Hardened version with AI-crawler policy |
| `Security/headers.md` | Header analysis + CSP reporting + Dependabot config |
| `Accessibility/axe-report.md` | Full scan, fix code, reproduction command |
| `Performance/cls-fix.md` | Root-cause analysis + before/after measurements |
| `Content/release-notes-v0.3.0.md` | Publishable release notes |
| `Content/copy-rewrites.md` | Rewritten description, README opener, FAQ |
| `SEO/findings.md` | Signal-by-signal table + keyword gaps |
| `Design/ui-recommendations.md` | Prioritised UI improvements |
| `Evidence/snapshot.txt` | Raw measurements, timestamped |

---

## Method

Every finding is tagged **[MEASURED]** (a tool produced it), **[OBSERVED]**
(directly visible), or **[JUDGEMENT]** (professional opinion, labelled).

Tools: `axe-core` 4.x via Playwright · Chrome DevTools Protocol · `curl` ·
GitHub REST API · official `luau-compile` · the project's own `balance_sim.py`.

**Not claimed:** search rankings, conversion rates, traffic, real-user CWV, or
competitor internals. None were accessible, so none are asserted. The repo is
hours old — growth trends cannot exist yet, and any figure suggesting otherwise
would be fabricated.

---

## Do these four things first (~1 hour total)

1. **Cut release `v0.3.0`** with the `.rbxl` attached — CI already builds and
   discards this file. Turns a five-step evaluation into a double-click.
2. **Fix or remove the red CI badge** — it reports failure while all checks pass
   locally. A lying badge is worse than no badge.
3. **Deploy the pending CLS + a11y fixes** — already committed, needs one command.
4. **Set the repo social preview** to the existing banner — 5 minutes, improves
   every shared link permanently.
