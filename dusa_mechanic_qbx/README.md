# Dusa Mechanic for QBX + OX

A complete dusa_mechanics-style mechanic system for FiveM, built **from scratch** for **QBX Core**, **ox_lib**, **ox_target**, **ox_inventory** and **oxmysql**. Includes a custom modern NUI, multi-shop vehicle lifts, repair, performance tuning, cosmetics, NOS, towing, diagnostic scanner and a full boss/employee/society system.

---

## Features

| # | Module | Highlights |
|---|--------|------------|
| 1 | **Repair** | Tires, windows, body, engine, full restore, cleaning. Server-side validated pricing. |
| 2 | **Performance Tuning** | Engine 1-4, Brakes 1-3, Transmission 1-3, Suspension 1-4, Armor 1-5, Turbo |
| 3 | **Visual Customization** | Primary/Secondary colors, Pearl, Wheel color, Neons, Xenons, Tire smoke, Plate styles |
| 4 | **NOS / Nitrous** | Install kit, refill, in-game NUI HUD, **LSHIFT** keybind to boost, server-synced fuel |
| 5 | **Vehicle Lifts** | 3D `prop_carlift_01` props at every shop, raise/lower animation, vehicle snapping |
| 6 | **Job System** | Boss menu (society balance, deposit/withdraw, hire/fire/promote), duty toggle, ox_inventory stash |
| 7 | **Towing** | `/mechtow` to spawn flatbed, `/mechhook` to hook, drive to impound for payout |
| 8 | **Diagnostic Scanner** | Reads body/engine/wear/NOS state. Item: `diagnostic_scanner` |

---

## Dependencies

- [qbx_core](https://github.com/Qbox-project/qbx_core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [oxmysql](https://github.com/overextended/oxmysql)

---

## Installation

1. **Copy** the `dusa_mechanic_qbx` folder into `resources/[scripts]/` (or any subfolder of your server's resources).
2. **Run the SQL** in `sql/install.sql` against your QBX database (creates 3 tables).
3. **Add items** to your `ox_inventory/data/items.lua`:
   ```lua
   ['repairkit']           = { label = 'Repair Kit', weight = 4500, stack = true, close = true },
   ['advancedrepairkit']   = { label = 'Advanced Repair Kit', weight = 6000, stack = true, close = true },
   ['cleaningkit']         = { label = 'Cleaning Kit', weight = 2000, stack = true, close = true },
   ['nos_bottle']          = { label = 'NOS Bottle', weight = 1500, stack = true, close = true },
   ['nos_refill']          = { label = 'NOS Refill', weight = 800, stack = true, close = true },
   ['diagnostic_scanner']  = { label = 'OBD-II Scanner', weight = 600, stack = false, close = true,
       client = { export = 'dusa_mechanic_qbx.useDiagnosticScanner' } },
   ['towrope']             = { label = 'Tow Rope', weight = 500, stack = true, close = true },
   ```
4. **Add the `mechanic` job** to your QBX `qbx_core/shared/jobs.lua` (it likely already exists).
5. **Add `ensure dusa_mechanic_qbx`** to `server.cfg` (after qbx_core and ox_* resources).
6. Restart server.

---

## Commands

| Command | Description |
|---------|-------------|
| `/mechmenu` | Open mechanic NUI for closest vehicle (testing only) |
| `/mechduty` | Toggle duty |
| `/mechtow`  | Spawn flatbed tow truck (must be mechanic, on-duty) |
| `/mechhook` | Hook nearest vehicle to your tow truck |

In-game keybind: **LSHIFT** to fire NOS when seated in a NOS-equipped vehicle.

---

## File Tree

```
dusa_mechanic_qbx/
├── fxmanifest.lua
├── config.lua
├── README.md
├── locales/en.lua
├── shared/utils.lua
├── sql/install.sql
├── server/
│   ├── main.lua          # callbacks, society, hire/fire wrappers
│   ├── repair.lua
│   ├── tuning.lua
│   ├── cosmetics.lua
│   ├── nos.lua
│   ├── job.lua
│   ├── towing.lua
│   └── diagnostic.lua
├── client/
│   ├── main.lua          # blips, ox_target zones, boss menu
│   ├── repair.lua
│   ├── tuning.lua
│   ├── cosmetics.lua
│   ├── nos.lua           # LSHIFT boost loop + HUD
│   ├── lifts.lua         # 3D lift props
│   ├── job.lua
│   ├── towing.lua
│   ├── diagnostic.lua
│   └── nui.lua           # NUI bridge
└── html/
    ├── index.html
    ├── style.css
    └── app.js
```

---

## Configuration cheatsheet (`config.lua`)

- `Config.JobName` – default `'mechanic'`
- `Config.UseSociety` – send earnings to society account
- `Config.Shops` – multiple shops with `boss`, `stash`, `duty`, `lifts`
- `Config.Prices` – all monetary values in one place
- `Config.Durations` – progress bar durations (ms)
- `Config.NOS` – fuel, drain, boost strength, keybind

---

## How customers interact

Two flows are supported:

1. **Self-service** (customer drives onto lift, uses ox_target menu themselves). Disable by setting `Config.RequireJob = true` (default).
2. **Mechanic-driven** (on-duty mechanic places vehicle on lift, opens NUI for the customer). Pricing is always charged from the **player using the menu** (server-validated).

Money charged → goes to the configured `Config.SocietyAccount` so the boss can withdraw.

---

## License

MIT. Sell, fork, modify freely.
