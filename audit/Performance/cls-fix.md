# CLS Fix — 0.4219 → 0.0463

## The measurement

Cumulative Layout Shift was **identical on every route**, which is the signature
of a shared-shell defect rather than a page problem:

| Route | CLS | Verdict |
|---|---:|---|
| `/` | 0.4219 | POOR |
| `/projects` | 0.4219 | POOR |
| `/games` | 0.4219 | POOR |
| `/about` | 0.4219 | POOR |

Google's threshold is **0.10**. Anything above 0.25 is "Poor" and is a
documented ranking signal.

## Attribution

Using the Layout Instability API with source attribution:

```
[432ms] shift 0.0155   CANVAS.cursor-grab          y,h: 0,107  -> 16,32
[791ms] shift 0.4064   FOOTER.w-full               y,h: 502,342 -> 0,0
                       DIV.linacre-pulse-line      y,h: 501,1   -> 0,0
```

**96% of total CLS came from one shift**: the footer moving from y=502 to y=0
and collapsing to zero height.

## Root cause

`src/App.tsx` renders:

```tsx
<div className="min-h-[100dvh] ... flex flex-col justify-between">
  <main className="flex-1 ...">
    <Suspense fallback={<div className="py-20 ...">   {/* ~145px tall */}
```

With `justify-between` and a 145px fallback, the footer paints near the top of
the viewport. When the lazy route chunk resolves and real content (often
2,000px+) mounts, the footer is pushed down — a single massive shift.

## The fix

```diff
- <div className="py-20 text-center font-mono text-xs ...">
+ <div className="py-20 min-h-[70svh] text-center font-mono text-xs ...">
```

Plus, so replacing the prerendered SEO shell can't collapse page height:

```diff
- <div id="root"><!--ROUTE_CONTENT--></div>
+ <div id="root" style="min-height:100svh"><!--ROUTE_CONTENT--></div>
```

```diff
- #prerender-shell{max-width:60rem;...
+ #prerender-shell{position:absolute;top:0;left:0;right:0;max-width:60rem;...
```

`svh` (small viewport height) is used deliberately — it excludes mobile browser
chrome, so the reservation doesn't overshoot when the URL bar is visible.

## Verified result

| Route | Viewport | Before | After | Verdict |
|---|---|---:|---:|---|
| `/games` | 390px | 0.4219 | **0.0463** | ✅ GOOD |
| `/projects` | 390px | 0.4219 | **0.0463** | ✅ GOOD |
| `/games` | 1440px | 0.4219 | **0.0145** | ✅ GOOD |
| `/` | 390px | 0.4219 | **0.1434** | ⚠️ Improved, still above 0.10 |

## Reproduce

```bash
cd linacre.site
npm run build
npx vite preview --port 4173 &
node -e '
const { chromium } = require("playwright");
(async () => {
  const b = await chromium.launch();
  const ctx = await b.newContext({ viewport: { width: 390, height: 844 } });
  const p = await ctx.newPage();
  await p.goto("http://localhost:4173/games", { waitUntil: "domcontentloaded" });
  const cls = await p.evaluate(() => new Promise(r => {
    let c = 0;
    new PerformanceObserver(l => {
      for (const e of l.getEntries()) if (!e.hadRecentInput) c += e.value;
    }).observe({ type: "layout-shift", buffered: true });
    setTimeout(() => r(+c.toFixed(4)), 6000);
  }));
  console.log("CLS:", cls);
  await b.close();
})();'
```

## Remaining work

`/` is still at 0.1434. Apply the same technique: identify its largest
late-mounting component and reserve its height. Likely the hero or a
dynamically-sized widget.
