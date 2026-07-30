# Accessibility Report — WCAG 2.2 AA

**Tool:** axe-core via Playwright · **Tags:** `wcag2a, wcag2aa, wcag21a, wcag21aa, wcag22aa`
**Viewports:** 1440×900 (desktop), 390×844 (mobile)

## Result summary

| Scan | Violations | Passes |
|---|---:|---:|
| Desktop — before | 1 critical | 24 |
| Mobile — before | 1 critical, 2 serious | 24 |
| **Desktop — after fix** | **0** | 24 |

## Critical violation found

```
[critical] aria-required-parent (x4)
  Certain ARIA roles must be contained by particular parents
  → .border-amber-color.rounded-t-lg.border-b-2
  → .border-transparent.rounded-t-lg.border-b-2:nth-child(2)
  → .border-transparent.rounded-t-lg.border-b-2:nth-child(3)
  → .border-transparent.rounded-t-lg.border-b-2:nth-child(4)
```

**WCAG 4.1.2 Name, Role, Value (Level A).**

The GameShowcase tab buttons declared `role="tab"` and `aria-selected` but had
no `role="tablist"` parent. Screen readers announce orphaned tabs with no group
context — a user hears "tab" with no indication of how many exist or which set
they belong to.

Compounding this, there was **no keyboard navigation** between tabs, violating
**WCAG 2.1.1 Keyboard (Level A)**. The ARIA tabs pattern requires arrow-key
movement.

## Fix

```tsx
<div
  role="tablist"
  aria-label="Project details"
  onKeyDown={e => {
    const i = TABS.findIndex(([id]) => id === tab);
    if (e.key === 'ArrowRight' || e.key === 'ArrowLeft') {
      e.preventDefault();
      const next = (i + (e.key === 'ArrowRight' ? 1 : -1) + TABS.length) % TABS.length;
      setTab(TABS[next][0]);
      document.getElementById(`sft-tab-${TABS[next][0]}`)?.focus();
    }
  }}
>
  {TABS.map(([id, label]) => (
    <button
      key={id}
      id={`sft-tab-${id}`}
      role="tab"
      aria-selected={tab === id}
      aria-controls={`sft-panel-${id}`}
      tabIndex={tab === id ? 0 : -1}          {/* roving tabindex */}
      className="... min-h-[44px] focus-visible:outline-2
                 focus-visible:outline-offset-2 focus-visible:outline-amber-color"
      onClick={() => setTab(id)}
    >
      {label}
    </button>
  ))}
</div>

<motion.div
  role="tabpanel"
  id={`sft-panel-${tab}`}
  aria-labelledby={`sft-tab-${tab}`}
  tabIndex={0}
>
```

Also applied:
- `aria-controls` on the changelog accordion buttons
- `prefers-reduced-motion` via `useReducedMotion()` on all showcase animation
- 44px minimum target height on tabs and accordion headers

## Verification

```
VIOLATIONS: 0
ArrowRight -> sft-tab-systems
ArrowRight -> sft-tab-changelog
tabpanel visible: true
```

## Remaining — pre-existing site chrome

Neither is in the showcase; both are in shared navigation, so fixing them
benefits every page.

### 1. Contrast on the mobile "More" button — WCAG 1.4.3 (AA)

```
[serious] color-contrast
  → button[aria-label="Open more navigation"] > span
```

Body text needs **4.5:1**. Raise the label colour until it passes:

```css
/* Verify with a contrast checker against the actual button background */
button[aria-label="Open more navigation"] > span {
  color: #cfcbdd; /* from a dimmer muted tone */
}
```

### 2. Chatbot toggle target size — WCAG 2.5.8 (AA, new in 2.2)

```
[serious] target-size
  → #btn-chatbot-toggle
```

Pointer targets must be at least 24×24 CSS px (44px is the usability
recommendation):

```css
#btn-chatbot-toggle {
  min-width: 44px;
  min-height: 44px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}
```

## Reproduce

```bash
npm install --no-save playwright @axe-core/playwright
node -e '
const { chromium } = require("playwright");
const AxeBuilder = require("@axe-core/playwright").default;
(async () => {
  const b = await chromium.launch();
  const ctx = await b.newContext({ viewport: { width: 1440, height: 900 } });
  const p = await ctx.newPage();
  await p.goto("https://www.linacre.site/games", { waitUntil: "networkidle" });
  await p.waitForTimeout(3000);
  const r = await new AxeBuilder({ page: p })
    .withTags(["wcag2a","wcag2aa","wcag21a","wcag21aa","wcag22aa"]).analyze();
  console.log("violations:", r.violations.length);
  r.violations.forEach(v => console.log(`[${v.impact}] ${v.id} x${v.nodes.length}`));
  await b.close();
})();'
```

## Note on scope

The **in-game** accessibility features (Reduced Motion, High Contrast, text
scale 80–150%, three colour-blind modes, server-persisted across devices) are
verified by **code inspection only**. No Roblox Studio was available in this
environment. They read as correctly implemented but require a manual pass.
