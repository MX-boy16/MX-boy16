# qbx_policeroles

A dynamic **police role & permission system** for FiveM, built for **qbox (qbx_core)** with the **ox suite** — `ox_lib`, `ox_inventory`, `ox_doorlock`, `ox_target`, and `oxmysql`.

The Chief of Police can create custom ranks (SWAT, K9, Detective, Traffic, etc.), assign them to officers in-game, and those role assignments grant access to specific **doors** and **role-gated stashes** (armory, evidence locker, SWAT bay…).

Roles are stored in **both** the config (as seed defaults) **and** the database, so they survive restarts, can be edited live, and are queryable by other scripts.

---

## Requirements

| Resource       | Notes                                       |
| -------------- | ------------------------------------------- |
| `qbx_core`     | qbox base framework                         |
| `ox_lib`       | UI menus, callbacks, notifications          |
| `ox_inventory` | role-gated stashes                          |
| `ox_doorlock`  | role-gated doors                            |
| `ox_target`    | stash interaction prompts                   |
| `oxmysql`      | database access                             |

---

## Installation

1. Drop the `qbx_policeroles` folder into your server's `resources/[your_folder]/`.
2. Add to your `server.cfg` **after** all the resources above:
   ```cfg
   ensure qbx_policeroles
   ```
3. Start the server once. The script auto-installs its SQL schema and seeds the default roles (set `Config.AutoInstallSQL = false` if you want to run the SQL manually from `sql/install.sql`).
4. Register your doors in `ox_doorlock` as usual (in-game `/doorlock` menu) and copy their **door IDs** (or `name`) into `Config.Doors`.
5. Adjust `Config.Stashes` coordinates to match your station layout.

---

## How permissions work

For a player to unlock a gated **door** or open a gated **stash**, **all three** must be true:

1. Their qbx_core job is `Config.PoliceJob` (default `police`).
2. They are **on duty** (for stashes) — toggle via `/duty`.
3. Their `citizenid` has at least one of the roles listed in the door's / stash's `required = { ... }` array, stored in the `police_roles` SQL table.

The **Chief** (qbx job grade `>= Config.LeaderGrade`, default `4`) bypasses role checks entirely and can manage every role.

Officers with the `can_manage_roles` permission (granted through a custom role) can also access the management menu if `Config.AllowDelegatedManagement = true`.

---

## Commands

| Command            | Who can use        | What it does                                       |
| ------------------ | ------------------ | -------------------------------------------------- |
| `/policeadmin`     | Chief / managers   | Opens the ox_lib management menu                   |
| `/policegive [id] [role]` | Chief / managers | Quickly grant a role from chat              |
| `/policetake [id] [role]` | Chief / managers | Quickly revoke a role from chat             |
| `/myroles`         | Any officer        | Lists your roles + duty status                     |
| `/duty`            | Any officer        | Toggles on/off duty                                |

---

## Management menu (`/policeadmin`)

* **Assign Role** – pick an online officer → pick a role → done.
* **Remove Role** – pick an online officer → pick one of their current roles → revoked.
* **View All Roles** – browse every role, its label, description, and attached permissions.
* **Create Role** (Chief or `can_create_role`) – ox_lib input dialog to define a brand-new role plus permission flags.
* **Delete Role** (Chief only) – removes a *custom* role from the DB. Default roles cannot be deleted.

---

## Default roles seeded

`chief`, `captain`, `lieutenant`, `sergeant`, `officer`, `cadet`, `swat`, `k9`, `detective`, `traffic`

Edit `Config.DefaultRoles` to change labels/descriptions/permissions; they re-sync on every restart **only if** `is_default = 1` in the DB (so custom edits to non-default roles are preserved).

---

## Permission flags

Permissions live on a role definition (any string you like). The script honors:

| Flag                 | Effect                                                          |
| -------------------- | --------------------------------------------------------------- |
| `can_manage_roles`   | Can open `/policeadmin` even without leader grade               |
| `can_assign_role`    | Can assign roles                                                |
| `can_remove_role`    | Can remove roles                                                |
| `can_create_role`    | Can create new role definitions                                 |
| `access_all`         | Bypasses every door/stash role check                            |

Use them in your own scripts via:
```lua
local ok = exports.qbx_policeroles:HasPermission(src, 'can_manage_roles')
```

---

## Exports (server)

```lua
exports.qbx_policeroles:HasRole(src, 'swat')           -- bool
exports.qbx_policeroles:HasAnyRole(src, {'swat','k9'}) -- bool
exports.qbx_policeroles:GetPlayerRoles(src)            -- { 'officer', 'swat' }
exports.qbx_policeroles:HasPermission(src, 'access_all')
exports.qbx_policeroles:IsOnDuty(src)
exports.qbx_policeroles:AssignRole(targetSrc, 'swat', grantedBy)
exports.qbx_policeroles:RemoveRole(targetSrc, 'swat')
```

ox_lib callbacks (great for inline checks in other resources):
```lua
lib.callback.await('qbx_policeroles:hasAccess', false, { 'swat', 'chief' })
lib.callback.await('qbx_policeroles:doorAccess', false, 'mrpd_armory')
lib.callback.await('qbx_policeroles:stashAccess', false, 'police_armory_swat')
```

---

## How door gating actually works

ox_doorlock fires `ox_doorlock:setState` when a player tries to unlock a door. This script listens for that event, looks up whether the door is gated (`Config.Doors`), checks the player's roles server-side, and **immediately re-locks** the door if the player isn't allowed. To the user this looks like the door simply refuses to open + they get a notification.

This means you can still keep ox_doorlock's normal groups/items config for non-role flows — this script only **adds** the role gate on top.

---

## Database schema

```
police_role_definitions   ← all role definitions (default + custom)
police_roles              ← citizenid → role assignments (M:N)
```

See `sql/install.sql`. Foreign key with `ON DELETE CASCADE` ensures deleting a role removes all its assignments.

---

## File layout

```
qbx_policeroles/
├── fxmanifest.lua
├── config.lua
├── shared/roles.lua
├── server/
│   ├── database.lua
│   ├── roles.lua
│   ├── permissions.lua
│   ├── doors.lua
│   ├── stashes.lua
│   ├── commands.lua
│   └── events.lua
├── client/
│   ├── main.lua
│   ├── menu.lua
│   ├── doors.lua
│   └── stashes.lua
├── sql/install.sql
└── locales/en.json
```

---

## Tweaks you'll probably want

* **Change job name** → `Config.PoliceJob`
* **Change leader grade** → `Config.LeaderGrade`
* **Add more doors** → append entries to `Config.Doors` with the right `doorId` from ox_doorlock
* **Add more stashes** → append to `Config.Stashes` (coords, slots, weight, required roles)
* **Add more default roles** → append to `Config.DefaultRoles`, restart resource
