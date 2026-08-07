# Suggested copy rewrites

## 1. Repo description (GitHub, 350 char limit)

**Current** — accurate but front-loads jargon:
> 🟢 Production-ready open-source Roblox idle-tycoon template. Server-authoritative Luau, session-locked DataStores, idempotent receipts, mobile-first UI built in code, and a CI balance simulator.

**Suggested** — leads with the outcome, keeps the credibility markers:
> 🟢 A complete Roblox idle-tycoon you can publish — with the hard parts already
> done. Session-locked saves, exploit-resistant economy, idempotent purchases,
> and a CI simulator that play-tests your balance. MIT.

**Why:** "Production-ready template" is what every template claims. "The hard
parts already done" names the actual value, and "a CI simulator that play-tests
your balance" is the genuinely unusual thing — lead with what nobody else has.

---

## 2. README opening

**Current** — the H1 is followed by a positioning line, then six badges, then
"What this is".

**Suggested** — add a one-sentence pitch and a 30-second path *above* the
strategy narrative:

```markdown
# Slime Factory Tycoon

**A complete, working Roblox idle tycoon you can publish — with the security
and save-integrity work already done.**

[badges]

> **Try it in 30 seconds:** [download the latest `.rbxlx`][latest] and open it
> in Studio. No toolchain required.

[latest]: https://github.com/DLinacre/slime-factory-tycoon/releases/latest
```

**Why:** the current README is 1,984 words. The evaluate-or-leave decision
happens in about ten seconds, and right now the fastest path to trying it is
below the fold.

---

## 3. Project page meta description

**Current** — 218 chars, will be truncated in SERPs:
> Slime Factory Tycoon, an open-source Roblox idle-tycoon built on a modular Luau service architecture, plus playable browser games including KushCloud and built-in Snake. Free and open source.

**Suggested** — 154 chars:
> Slime Factory Tycoon: an open-source Roblox idle-tycoon with a modular Luau
> architecture, plus playable browser games. Free, MIT licensed.

---

## 4. The disabled CTA

**Current:** `Play — Not Yet Available` (disabled, dead end)

**Suggested:** keep the honest disabled state, add a live secondary action.

```
[ 🎮 Play — Not Yet Available ]   [ ⭐ Star for launch updates ]
      (disabled, honest)               (live, captures intent)
```

**Why:** the honesty is a genuine asset and shouldn't change. But right now the
page tells an interested visitor "no" and offers nothing else. One live action
beside it converts intent that is currently discarded.

---

## 5. FAQ to add to the README

```markdown
## FAQ

**Can I sell a game made with this?**
Yes. MIT licence, no attribution required, keep all revenue.

**Do I need to credit you?**
No. Appreciated, never required.

**Will this get me moderated on Roblox?**
Nothing here violates Roblox policy. Hatch odds are published in-game, there are
no fake timers, and no real-money gambling framing. You are responsible for your
own content and any changes you make.

**Do I need Rojo?**
No. Download the `.rbxlx` from Releases and open it in Studio. Rojo is only for
live-syncing your editor.

**Why is the CI badge red?**
GitHub Actions has no runner minutes on this account, so jobs finish without
executing. Every check passes locally — run `./tools/verify.sh` to confirm.

**Is this actually production-ready?**
The architecture, security and save handling are. You still need your own art,
your own asset IDs, and a play-test pass before publishing.
```
