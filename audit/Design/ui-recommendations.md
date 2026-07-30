# UI Recommendations

## Verified working

- **[MEASURED]** 0 axe violations on `/games` after the tab fix
- **[MEASURED]** Clean reflow at 390px and 1440px — no horizontal scroll, no clipping
- **[MEASURED]** WebP with PNG fallback: banner 1,373KB → 97KB (93% smaller)
- **[OBSERVED]** Reuses the host site's design tokens rather than importing a
  second design system
- **[OBSERVED]** Rarity communicated by colour **and** text label — survives
  colour blindness

## Recommendations

### 1. Split the stat cards by audience — Medium
The four cards (23 modules / 3,724 lines / 16 achievements / 15 cosmetics) mix
developer metrics with gameplay facts. A player-facing visitor has no use for
"lines of Luau".

```
For players:      6 zones · 10 pets · 8h offline earnings · 16 achievements
For developers:   23 modules · 3,724 lines Luau · MIT · 0 dependencies
```

### 2. Fix the LCP image loading strategy — Medium
The banner is the LCP element but is `loading="lazy"`:

```diff
- loading="lazy"
+ loading="eager"
+ fetchpriority="high"
```

Plus a preload hint in `<head>` (see `Metadata/meta-tags.html`).

### 3. Add a skeleton to the Suspense fallback — Low
The current fallback is a spinner. A skeleton matching the final layout reduces
perceived load time and reinforces the height reservation that fixed CLS.

### 4. Surface the changelog's latest entry — Low
Release history is behind a tab. Showing the most recent version and date in the
header signals active maintenance without a click.

### 5. Add brand swatches to BRAND.md — Low
Inline colour chips make the palette scannable without opening a picker:

```markdown
| Token | Hex | |
|---|---|---|
| `slime` | `#78FF78` | ![](https://readme-swatches.vercel.app/78FF78?style=round) |
```
