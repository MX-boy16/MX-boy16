# 🏋️ gym_system — Full Gym Progression for QBX + ox

A complete, config-driven gym script for **QBox (qbx_core)** using **ox_lib, ox_inventory & ox_target**.

Train your character to grow **Strength**, **Stamina**, **Punch Power** and **Muscle** — with
**visible muscle growth** on freemode peds, a **membership system** (pay at the front desk OR own
the membership card), and consumable **supplements & steroids** that permanently boost your stats.

---

## ✨ Features

- **4 progression stats** (0–100): Strength, Stamina, Punch Power, Muscle — saved to player metadata, persists across relogs.
- **Real in-game effects**
  - Stamina → faster sprint + bigger stamina pool
  - Strength + Punch → stronger melee / unarmed damage
  - Muscle → **visible body growth** on `mp_m_freemode_01` / `mp_f_freemode_01` peds
- **Membership system**
  - Buy a **30-day membership** at the front desk ped, OR
  - Own / redeem the **Gym Membership Card** item for premium (lifetime) access
  - Equipment is locked unless you have access
- **Gym equipment** (treadmill, bench press, punching bag with skill-check, pull-up bar) via ox_target
- **Consumables that grow your character**
  - Protein Powder ×3 flavours (Chocolate / Vanilla / Strawberry) → muscle + strength
  - Pre-Workout ×3 flavours → stamina + temporary sprint/energy buff
  - Creatine → strength + muscle
  - Injectable Steroids → huge gains, small health cost (risk/reward)
- **100% config driven** — works with ANY gym MLO (just set the coords).

---

## 📦 Installation

1. **Drop the folder** `gym_system` into your `resources` directory.
2. Add to your `server.cfg` (after qbx_core, ox_lib, ox_inventory, ox_target):
   ```cfg
   ensure gym_system
   ```
3. **Register the items** — open `install/items.lua`, copy every entry and paste it into
   `ox_inventory/data/items.lua` (inside the `return { ... }` table).
4. *(Optional)* Add item images to `ox_inventory/web/images/` named exactly:
   `protein_choco.png`, `protein_vanilla.png`, `protein_strawberry.png`,
   `preworkout_choco.png`, `preworkout_vanilla.png`, `preworkout_strawberry.png`,
   `creatine.png`, `steroids.png`, `gym_membercard.png`.
5. Restart the server (or `ensure ox_inventory` then `ensure gym_system`).

---

## 🗺️ Using YOUR gym MLO

Everything is in **`config.lua`**. Set the coordinates to match your MLO interior:

- `Config.Clerk.coords` → where the front-desk membership ped stands.
- `Config.Equipment[*].coords` → each piece of equipment (box-zone center).
  Set `Config.Debug = true` to see the zones in-game, stand on the prop, and read your
  coords with `/coords` (or any tool) to fine-tune.

> The defaults point at the stock GTA **Muscle Sands** gym so you can test immediately,
> then move them into your MLO.

### Getting coordinates quickly
Set `Config.Debug = true`, restart the resource, and the equipment zones render as boxes.
Walk to each gym prop and copy your position into the matching `coords` field.

---

## ⚙️ Key config options

| Setting | What it does |
|---|---|
| `Config.Account` | `'bank'` or `'cash'` for all purchases |
| `Config.MaxLevel` | Max level per stat (default 100) |
| `Config.Membership.durationDays` | Membership length (default **30**) |
| `Config.Membership.price` | Price of a 30-day membership |
| `Config.Membership.cardGrantsLifetime` | Card redeem = lifetime (true) or 30 days (false) |
| `Config.Membership.ownershipGrantsAccess` | Just owning the card grants access |
| `Config.Effects.maxSprintMultiplier` | Sprint speed at max stamina (native cap 1.49) |
| `Config.Effects.maxMeleeMultiplier` | Melee/punch damage at max strength |
| `Config.Items` | Edit every supplement's stat gains & buffs |

---

## 💪 How muscle growth works (please read)

Visible muscle uses the GTA freemode **muscle tone** stat (`MP0_MUSCLE_TONE`) plus the
strength stat, re-applied to your ped. This visibly thickens the body **only on freemode
multiplayer peds** (`mp_m_freemode_01` / `mp_f_freemode_01`), which QBX uses by default for
created characters. On story-mode peds (Michael/Franklin/etc.) the stat is set but the body
mesh won't morph — that's a GTA limitation, not a bug. Toggle with
`Config.Effects.applyMuscleVisual`.

---

## 🧪 Exports

Other resources can read/grant gym stats:

```lua
-- server
GrantStatXp(source, { strength = 10, muscle = 5 })   -- grant XP
local hasAccess = PlayerHasAccess(source)            -- membership check
```

---

## 🛠️ Dependencies
- qbx_core
- ox_lib
- ox_inventory
- ox_target

Enjoy the gains! 🏋️‍♂️
