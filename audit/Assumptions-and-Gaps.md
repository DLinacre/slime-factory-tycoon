# Assumptions, Corrections & Gaps

**Audit date:** 2026-07-30 · **Auditor:** multi-disciplinary review · **Depth:** Full professional

---

## 1. Corrections to auto-resolved inputs

The brief auto-filled several fields incorrectly. Correcting them changes what a
useful audit even *is*, so they're addressed first rather than buried.

| Field | Auto-resolved as | Corrected to | Why it matters |
|---|---|---|---|
| **Product / brand name** | "Github" | **Slime Factory Tycoon** | GitHub is the *host*, not the product. Auditing "Github" as a brand would be auditing Microsoft's website. |
| **Market / niche** | `[object Object]` | **Open-source Roblox game development templates** | A JS serialisation bug leaked into the brief. The real niche has specific norms (Rojo, Luau, DevForum) that drive most recommendations. |
| **Target type** | "Website / Web app" | **Two surfaces** (see below) | The named URL is a *code repository*, not a website. Auditing it purely as a web page would produce nonsense findings about GitHub's own chrome. |

### The target is genuinely two surfaces

The brief names a GitHub repository but adds `https://www.linacre.site/games`
as context. These are different things and are scored separately:

| Surface | What it is | Who it serves | What I can control |
|---|---|---|---|
| **A. The repository** | `github.com/LIN4CRE/slime-factory-tycoon` | Developers evaluating a template | README, docs, topics, community files, repo metadata |
| **B. The project page** | `linacre.site/games` | Players, recruiters, general visitors | Full HTML/CSS/JS, headers, SEO, performance |

Surface A is rendered inside GitHub's chrome. I cannot change GitHub's CSS,
security headers, or Core Web Vitals — so scoring the repo on "page performance"
would be measuring Microsoft's engineering, not this project's. Categories that
only apply to a real website are scored **against Surface B**, and this is
labelled everywhere it occurs.

---

## 2. Evidence standard

Every finding in this audit is one of:

- **[MEASURED]** — a tool produced the number. Command and output recorded.
- **[OBSERVED]** — directly visible in the artefact.
- **[JUDGEMENT]** — professional opinion, labelled as such.

Tools used, all run during the audit:

| Tool | Purpose |
|---|---|
| `axe-core` 4.x via Playwright | WCAG 2.2 A/AA automated checks, desktop + mobile |
| Chrome DevTools Protocol (Playwright) | LCP, CLS, FCP, TTFB, request waterfall |
| `curl -I` | Security headers, HTTP status, redirects |
| GitHub REST API | Repo metadata, community profile, tree sizes |
| `luau-compile` (official Luau toolchain) | Syntax validation of all 23 modules |
| `tools/balance_sim.py` | Game progression modelling |

---

## 3. What I could NOT verify — and refuse to guess

These gaps are stated rather than filled with plausible-sounding numbers.

| Gap | Why | Consequence |
|---|---|---|
| **Real-user Core Web Vitals (CrUX)** | Site has insufficient traffic for a CrUX record | All performance figures are **lab data**, unthrottled, from one location. Field data will be worse. |
| **Search rankings / impressions** | Requires Search Console access | No keyword-position claims are made anywhere. |
| **Conversion rates** | No analytics access | CRO section covers *mechanisms*, never rates. |
| **Traffic, users, stars over time** | Repo is hours old (created 2026-07-30T17:57Z) | Growth trends cannot exist yet. |
| **Competitor internals** | Only public surfaces observable | Competitive section compares to *documented best practice*, not invented competitor stats. |
| **Roblox experience metrics** | Game is unpublished | No player counts, visits, revenue, or ratings appear in this audit or on the site. |
| **Throttled mobile performance** | Sandbox has no reliable network throttling | Lab figures are optimistic. Treat LCP 1.04s as a floor, not a promise. |

---

## 4. Conflict of interest — disclosed

**I built both surfaces being audited.** This audit reviews my own work from
earlier in this session.

Mitigations applied:

1. **Automated tools over opinion** wherever a tool exists. `axe-core` doesn't
   care who wrote the component.
2. **The audit found and fixed real defects in my own code**, documented below.
   An audit that finds nothing is not an audit.
3. **Scores are deliberately conservative.** Where I was uncertain, I scored
   down. A 0-star, hours-old repository cannot honestly score highly on
   community or traction no matter how good the code is.

### Defects this audit found in my own work

| Defect | Severity | Status |
|---|---|---|
| `aria-required-parent` — `role="tab"` without `role="tablist"` in GameShowcase | **Critical (WCAG 4.1.2)** | ✅ Fixed, re-verified 0 violations |
| Site-wide CLS 0.4219 (footer collapse on hydration) | **High (fails CWV)** | ✅ Fixed → 0.0463 on /games |
| Repo `homepage` pointed at itself | Medium | ✅ Repointed to project page |
| Community health 71% (missing CoC, issue templates, PR template) | Medium | ✅ Now 100% |
| No keyboard navigation on tabs | High (WCAG 2.1.1) | ✅ Arrow keys + roving tabindex added |

---

## 5. Scope boundaries

**In scope:** repository presentation and discoverability; the `/games` page
experience across mobile and desktop; public technical signals (headers,
robots, sitemap, schema); code quality signals visible to an evaluating
developer; content, brand, and conversion mechanics.

**Explicitly out of scope:** GitHub's own UI, performance, or security posture;
the Luau game code's *runtime* behaviour inside Roblox (no Studio available in
this environment — it is syntax-verified only); the rest of linacre.site beyond
`/games` and shared shell code; anything requiring authenticated access.

---

## 6. One honest caveat about deployment

Changes committed during this audit are pushed to `main` on both repositories.
The site deploys via `vercel deploy --prod` per the project's own `AGENTS.md`,
and **I have no Vercel credentials**. The CLS and accessibility fixes are
verified against a local production build (`npm run build` + `vite preview`),
not against the live domain. They will not appear at `linacre.site` until
someone runs the deploy.

Verification commands are given in `Performance/cls-fix.md` and
`Accessibility/axe-report.md` so the results can be independently reproduced.
