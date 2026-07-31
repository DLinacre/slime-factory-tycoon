## What changed

<!-- One or two sentences. -->

## Why

<!-- Which of retention, engagement, or revenue does this serve?
     If it serves none, say why it's still worth the complexity. -->

## Checklist

- [ ] `./tools/verify.sh` passes
- [ ] All Luau modules compile (`luau-compile`)
- [ ] No client-authoritative currency or state introduced
- [ ] Tunable numbers live in `GameConfig` / `Content`, not hardcoded in services
- [ ] Comments explain *why*, not *what*
- [ ] Updated `CUSTOMIZING.md` / `DEVELOPMENT.md` / README if user-facing

## Balance changes

<!-- REQUIRED if you touched costs, growth rates, or multipliers.
     Paste `python3 tools/balance_sim.py --hours 6` before and after. -->

## Screenshots / Demo

<!-- For any UI or visible change, include mobile (390px) and desktop. -->

## Testing

<!-- How did you test this? (Simulator, manual play, etc.) -->
