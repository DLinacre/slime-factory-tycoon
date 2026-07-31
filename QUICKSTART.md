# ⚡ Quickstart — Slime Factory Tycoon

Get a **working, publishable Roblox game** in under 60 minutes.

> No coding required for a first publish. Everything important is already done.

---

## 1. Get the game (30 seconds)

**Easiest way:**
1. Go to [Releases](https://github.com/DLinacre/slime-factory-tycoon/releases/latest)
2. Download **`SlimeFactoryTycoon-v0.3.0.rbxlx`**
3. Open it in Roblox Studio

---

## 2. One-time setup (2 minutes)

1. In Roblox Studio go to:
   **File → Game Settings → Security**
2. Turn **ON** "Enable Studio Access to API Services"
   > This is required for DataStores to work.

---

## 3. Add your monetization (5–10 minutes)

1. Go to the [Creator Dashboard](https://create.roblox.com/)
2. Create **Gamepasses** and **Developer Products**
3. Open `src/shared/GameConfig.luau` (or the version inside the place)
4. Replace every `id = 0` with your real asset IDs.

**Recommended items to create:**
- 2x Goo (199 Robux)
- Auto Clicker (149)
- VIP (399)
- Server-wide Boost (199) ← highest ROI
- Crystal packs (99 / 499 / 999)

> Anything left at `0` is safely skipped.

**Helper tool:**
```bash
python3 tools/replace_ids.py
```

---

## 4. Publish (2 minutes)

1. Click **File → Publish to Roblox As...**
2. Choose your game or create a new one
3. Set a good **icon** (use `assets/icon-512.png`)
4. Add thumbnails (use the screenshots in `assets/`)
5. Write a short description (copy ideas from README)

---

## 5. (Optional but recommended) Test balance

```bash
python3 tools/balance_sim.py --hours 6
```

Make sure the numbers feel right for your game.

---

## Next steps after publishing

- Playtest on mobile (most players are on mobile)
- Watch your D1 retention in Roblox Analytics
- Ship small updates every week
- Read `STRATEGY.md` for monetization and retention advice

---

## Want to develop properly?

```bash
git clone https://github.com/DLinacre/slime-factory-tycoon.git
cd slime-factory-tycoon
aftman install          # or rokit install
rojo serve
```

Then connect the **Rojo plugin** in Studio.

---

**You're ready to launch.**

All the hard engineering (saves, security, balance, UI, monetization) is already complete.

Focus on your theme, art, and numbers.

Good luck — and ship weekly! 🚀

---

**Need help?**  
Copy the prompt from the README into any LLM, or open an issue.