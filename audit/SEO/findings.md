# SEO Findings

## Surface B — linacre.site/games [MEASURED]

| Signal | Status | Note |
|---|---|---|
| HTTPS + HSTS | ✅ | `max-age=63072000; includeSubDomains; preload` |
| robots.txt | ✅ | Well-formed, sitemap declared, AI crawlers handled deliberately |
| sitemap.xml | ✅ | 19 URLs, `/games` present with `lastmod` |
| Canonical | ✅ | Self-referential, correct |
| Title | ✅ | 78 chars, keyword-led |
| Meta description | ⚠️ | **218 chars — will truncate at ~160** |
| OG/Twitter tags | ✅ | `summary_large_image` with a real banner |
| Prerendering | ✅ | 22 static routes; crawlable without JS |
| H1 | ✅ | One per page |
| Image alt text | ✅ | Descriptive throughout the showcase |
| Schema | ⚠️ | `VideoGame` present; `SoftwareSourceCode` + `BreadcrumbList` missing |
| CWV — LCP | ✅ | 1,036 ms (lab) |
| CWV — CLS | ✅ | 0.0463 after fix (was 0.4219 — **was a ranking risk**) |

## Surface A — GitHub repo [MEASURED]

| Signal | Status | Note |
|---|---|---|
| Topics | ✅ | 20/20 — at cap, well-targeted |
| Description | ✅ | Keyword-rich, under limit |
| Homepage | ✅ | Fixed during audit — was self-referential |
| README | ✅ | 1,984 words, 16 sections, images render |
| **Releases** | 🔴 | **0.** Biggest SEO miss — release pages are separately indexed and weighted in GitHub search |
| Pages site | ⚠️ | Disabled — no indexable docs surface |
| Community profile | ✅ | 100% after audit fixes (was 71%) |
| Social preview | ⚠️ | Not set — shared links get a generic card |

## Keyword opportunities [JUDGEMENT]

| Query | Intent | Coverage | Action |
|---|---|---|---|
| roblox tycoon template | Commercial | Weak | Needs a release page |
| roblox datastore session locking | Technical | **Excellent content, zero visibility** | Publish `SECURITY.md` as an article |
| roblox remoteevent validation | Technical | Excellent content, buried | Same |
| roblox anti exploit | Technical | Good | Same |
| roblox idle game source code | Commercial | Weak | Release + DevForum |
| rojo project template | Navigational | Weak | Docs site |

**The pattern:** the project's strongest SEO asset is technical writing that
currently has no indexable home. `SECURITY.md` and `OPTIMISATION.md` would rank
for real developer queries if published as pages with proper canonicals.

## Prioritised

1. **Cut a release** — highest-impact single action on Surface A
2. **Trim meta description to ≤160**
3. **Add the two JSON-LD blocks** (files ready in `Schema/`)
4. **Publish the technical docs** as indexable pages
5. **Set the social preview image**
