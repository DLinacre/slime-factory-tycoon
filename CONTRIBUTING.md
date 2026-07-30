# Contributing

Thanks for helping out. Keep it simple — this project's whole value is that a beginner can read it.

## Before you open a PR

```bash
stylua src                                    # format
selene src                                    # lint
python3 tools/balance_sim.py --hours 6 --check   # balance gate
rojo build default.project.json -o /tmp/t.rbxlx  # it must build
```

## Principles this codebase follows

1. **The server decides value. The client sends intent.** Any PR where the client sends an amount of currency will be closed.
2. **All tunable numbers live in `GameConfig.luau`.** No magic numbers in service code.
3. **One loop for all players**, never one loop per player.
4. **Explain the *why* in comments**, not the *what*. The reader is learning.
5. **If a feature won't measurably improve retention, engagement or revenue, it doesn't ship.** Say so in the PR description.

## Changing balance

Any change to costs, growth rates, or multipliers must include the simulator output in the PR description, before and after.
