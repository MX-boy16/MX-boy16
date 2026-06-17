# Mechanic Tablet — QBX + OX

A standalone, **tablet-based** mechanic tool for FiveM. The mechanic carries a single item — a **physical tablet** — and uses it from inside any vehicle to access a clean tabbed UI for:

- **Looks** — paint, neons, xenons, plate style
- **Engine** — engine, brakes, transmission, suspension levels, turbo
- **Stance** — *advanced sliders for* **tire width, wheel size, ride height, track width, camber (front + rear)** with live preview
- **Wheels** — wheel type + design index

The tablet is gated to specific jobs via a **configurable list** so you can add more mechanic-like jobs later.

> No shops. No lifts. No society menus. Just one item, used in any car.

---

## Dependencies

- `qbx_core`
- `ox_lib`
- `ox_inventory`
- `oxmysql`

---

## Install

1. Copy `mechanic_tablet/` into `resources/[scripts]/`.
2. Run `sql/install.sql` against your QBX database.
3. Add the item to **`ox_inventory/data/items.lua`**:
   ```lua
   ['mechanic_tablet'] = {
       label = 'Mechanic Tablet',
       weight = 500,
       stack = false,
       close = true,
       description = 'A diagnostic & tuning tablet for licensed mechanics.',
       client = {
           export = 'mechanic_tablet.useMechanicTablet'
       }
   },
   ```
4. Add `ensure mechanic_tablet` to `server.cfg` (after `qbx_core` and `ox_*`).
5. Give yourself the item:
   ```
   /giveitem <id> mechanic_tablet 1
   ```
6. Get in a car, use the item from your inventory.

---

## Adding more jobs later

Open `config.lua` and edit:

```lua
Config.AllowedJobs = {
    'mechanic',
    'tuner',
    'lscustoms',
    'racing_team',   -- just append
}
```

Optional duty check:
```lua
Config.RequireOnDuty = true
```

That's it. No code changes required.

---

## What the tablet does

| Tab | Action | Native(s) used |
|-----|--------|----------------|
| Looks | Primary/Secondary paint | `SetVehicleCustomPrimaryColour` / `SetVehicleCustomSecondaryColour` |
| Looks | Neons | `SetVehicleNeonLightEnabled` + `SetVehicleNeonLightsColour` |
| Looks | Xenons | `ToggleVehicleMod(22)` + `SetVehicleXenonLightsColor` |
| Looks | Plate style | `SetVehicleNumberPlateTextIndex` |
| Engine | Engine/Brakes/Trans/Susp | `SetVehicleMod(11/12/13/15, lvl)` |
| Engine | Turbo | `ToggleVehicleMod(18, true)` |
| Stance | Tire width | `SetVehicleWheelWidth` |
| Stance | Wheel size | `SetVehicleWheelSize` |
| Stance | Ride height | `SetVehicleSuspensionHeight` |
| Stance | Track width | `SetVehicleWheelXOffset` per wheel |
| Stance | Camber F/R | `SetVehicleWheelYRotation` per wheel |
| Wheels | Wheel type + design | `SetVehicleWheelType` + `SetVehicleMod(23)` |

All stance values are **saved to MySQL per plate** and re-applied when any player enters the car.

---

## Config quick reference (`config.lua`)

```lua
Config.TabletItem      = 'mechanic_tablet'    -- ox_inventory item
Config.AllowedJobs     = { 'mechanic' }        -- add more here
Config.RequireOnDuty   = false
Config.FakeFailForOthers = true                -- non-mechs see a fake error
Config.MustBeInVehicle = true
Config.MustBeDriver    = true
Config.MustBeStopped   = true
Config.ChargeForMods   = false                 -- mechanics tune for free
Config.PersistStance   = true
```

---

## File tree

```
mechanic_tablet/
├── fxmanifest.lua
├── config.lua
├── README.md
├── shared/utils.lua
├── sql/install.sql
├── server/main.lua             # job auth, charging, persistence
├── client/
│   ├── main.lua                # item use, job check, vehicle restore
│   ├── stance.lua              # tire width, ride height, camber, track
│   ├── looks.lua               # paint, neons, xenons, plate
│   ├── engine.lua              # perf levels, turbo
│   └── nui.lua                 # NUI bridge
└── html/
    ├── index.html              # tablet UI
    ├── style.css
    └── app.js
```

---

## Commands

| Command | Description |
|---------|-------------|
| `/mechtab` | Open the tablet (mostly for testing — normally triggered via item use) |

---

## Networking / "I tried to tune someone else's car"

The tablet requires **network ownership** of the vehicle before applying any change. This is handled automatically:

1. When you open the tablet on a vehicle, the resource pre-warms network control in the background.
2. If another player is already sitting inside the car you're targeting, the tablet refuses to open and tells you to ask them to step out.
3. If we can't acquire control within ~1.5s (e.g., the vehicle is owned by a player far away), you'll see a friendly warning instead of a silent failure / freeze.
4. Stance sliders re-use the same control session — they don't re-request control on every drag.

If a change still doesn't apply, get in the driver seat of the car first; that always gives you network control.

---

## License

MIT.
