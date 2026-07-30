# Priority Roadmap

Sequenced by **impact ÷ effort**. Every item states what it unblocks.

---

## 🔴 Immediate (today) — ~2 hours total

These four are the entire difference between "impressive code nobody sees" and
"a template people can actually try."

### 1. Cut release `v0.3.0` with the built `.rbxl` attached — 30 min
**Why:** The CI workflow already builds this artefact and discards it. Right now
a developer must clone → install Aftman → install Rojo → build → open Studio
before seeing anything. A release turns that into a double-click.

```bash
cd slime-factory-tycoon
rojo build default.project.json --output SlimeFactoryTycoon-v0.3.0.rbxlx

gh release create v0.3.0 \
  SlimeFactoryTycoon-v0.3.0.rbxlx \
  --title "v0.3.0 — Architecture & brand foundation" \
  --notes-file .github/release-notes-v0.3.0.md
```

> Draft notes are in `Content/release-notes-v0.3.0.md`.

### 2. Resolve the failing CI badge — 15 min
**Why:** The README's first badge is red because Actions has no runner minutes.
On an unknown repo, a failing build reads as abandoned. **A lying badge is worse
than no badge.**

Options, in order of preference:
- **A.** Enable GitHub Actions billing → badge goes green with zero code change.
- **B.** Replace with an honest static badge until billing is sorted:
  ```markdown
  [![Checks](https://img.shields.io/badge/checks-verify.sh%20passing-brightgreen)](tools/verify.sh)
  ```
- **C.** Remove the badge entirely.

### 3. Deploy the pending CLS + accessibility fixes — 5 min
**Why:** Both are committed to `main` but not live. CLS 0.42 → 0.05 is a
documented ranking signal, and the ARIA fix resolves a critical WCAG failure.

```bash
cd linacre.site
vercel deploy --prod --yes --project linacre-site-repo
```

> ⚠️ Requires Vercel credentials I don't have.

### 4. Set the repo social preview image — 5 min
**Why:** Every shared link currently gets GitHub's generic auto-card instead of
the banner that already exists.

Settings → General → Social preview → upload `assets/banner.png`.

---

## 🟠 Short term (1–2 weeks) — ~12 hours

### 5. Record a 15-second gameplay GIF — 1–2 h
**Why:** *The single highest-converting asset a game repository can have.* A
game project with no moving images asks visitors for blind faith.

Capture in Studio: tap the vat → numbers climb → buy an upgrade → rebirth flash.
Target under 5MB, place directly under the README's H1.

### 6. Publish an unlisted Roblox place — 3 h
**Why:** Converts "trust me" into "try it", and unlocks the real Play button on
the project page (currently a disabled dead-end).

Then set `links.roblox` in `game.manifest.json` and run:
```bash
python3 tools/sync_site.py --site ../linacre.site
```
The showcase automatically switches from the disabled state to a live CTA — no
component change needed.

### 7. Add lead capture beside the disabled CTA — 2 h
**Why:** 100% of interested traffic is currently lost. Even without email
infrastructure, "⭐ Star for launch updates" costs nothing and is measurable.

### 8. Capture real screenshots — 1 h
**Why:** The manifest's `screenshots: []` currently renders "Coming Soon" —
honest, but a gap. Populate the array and the gallery renders automatically.

### 9. Post to DevForum and r/robloxgamedev — 2 h
**Why:** Zero stars is a *distribution* problem, not a quality problem. Lead
with the balance simulator and the session-locking write-up — both are
genuinely novel and will earn technical readers.

### 10. Add `CHANGELOG.md` + `dependabot.yml` — 1.5 h
**Why:** Developers look for a changelog at root, not inside a JSON manifest.
Dependabot closes an unmonitored supply-chain gap.

### 11. Fix the two remaining mobile a11y defects — 1 h
**Why:** Contrast and target-size failures in shared chrome affect every page.
Snippets in `Accessibility/axe-report.md`.

### 12. Trim the meta description to ≤160 chars — 15 min
**Why:** Currently 218 chars; Google truncates. Ready in `Metadata/meta-tags.html`.

---

## 🟡 Medium term (1–3 months) — ~20 hours

### 13. GitHub Pages documentation site — 4 h
`SECURITY.md` and `OPTIMISATION.md` contain genuinely search-worthy technical
content that is invisible because it only exists inside an unlinked repo.
Publishing them as indexable pages targets real developer queries
("roblox datastore session locking", "roblox remoteevent validation").

### 14. Add `SoftwareSourceCode` + `BreadcrumbList` JSON-LD — 30 min
Files ready in `Schema/`.

### 15. ~~Font optimisation~~ — CLOSED, no action needed
Inspection showed the fonts were already self-hosted, `unicode-range` subset,
`font-display: swap`, and preloaded. The original recommendation was based on
total weight without checking how it was delivered. No work required.

### 16. Fix the LCP image loading strategy — 30 min
The banner is the LCP element but is `loading="lazy"`. Switch to
`loading="eager"` + `fetchpriority="high"`, and add the preload from
`Metadata/meta-tags.html`.

### 17. Ship one seasonal event — 4 h
The framework exists; `Content.Seasons` is deliberately empty. Declaring one
proves the content pipeline works end to end and gives the project a live
update story.

### 18. Wire `AnalyticsService` funnel instrumentation — 3 h
Post-launch decisions need data. Instrument tutorial → first upgrade → first
rebirth → first purchase.

### 19. AI setup assistant block in the README — 1 h
A copy-paste prompt giving any LLM enough repo context to walk a developer
through setup. Near-zero cost against the biggest funnel leak.

### 20. Balance-tuning copilot — 1 d
Feed `balance_sim.py` output to an LLM for suggested `GameConfig` adjustments.
The simulator already emits exactly the structured data needed.

### 21. Fix remaining CLS on `/` — 2 h
Still 0.1434 after the shell fix. Apply the same height-reservation technique to
its largest late-mounting component.

---

## 🟢 Long term (3+ months) — strategic

### 22. Build a "Built with this" showcase
Even empty with an invitation, it signals the project expects real adoption.
Once populated, it's the strongest possible social proof.

### 23. Semantic versioning discipline
Adopters need to know what breaks between versions. Establish the convention
before anyone depends on it — retrofitting is painful.

### 24. Video walkthrough
A 5-minute "clone to running game" video reaches an audience that won't read a
README.

### 25. Community infrastructure
Discussions are enabled but empty. Seed 3–5 real threads. Consider Discord only
once there's traffic to justify it — an empty server looks worse than none.

### 26. Publish the game properly
The template's credibility ultimately rests on the game working. A published,
maintained experience with real retention data would validate every claim the
documentation makes.

### 27. Accessibility statement page
Given the genuinely strong a11y work, a public statement is both good practice
and a differentiator.

---

## Sequencing logic

```
Week 0  ██ Release + badge + deploy + social image   → makes it trustworthy
Week 1  ████ GIF + screenshots + demo place          → makes it provable
Week 2  ███ Distribution posts + lead capture        → makes it discoverable
Month 2 █████ Docs site + SEO + performance          → makes it findable
Month 3 ████ Seasonal content + analytics            → makes it alive
Ongoing ███ Community + versioning + showcase        → makes it durable
```

**The pattern worth internalising:** the project is over-engineered relative to
its distribution. Every Critical item is under 30 minutes, and none require new
engineering. The bottleneck is entirely in proof and reach — which is a much
cheaper problem to fix than the one this project has already solved.
