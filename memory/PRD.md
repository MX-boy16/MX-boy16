# qbx_policeroles — FiveM Resource PRD

## Problem statement
Build a fully working FiveM police job script for qbox (qbx_core) + ox suite where the leader of police (Chief) can add custom roles (SWAT, K9, Detective, Traffic, etc.) to officers, and those roles grant access to special doors and inventories.

## User personas
- **Chief of Police** (qbx job grade >= LeaderGrade): full control over role definitions and assignments.
- **Delegated manager** (any officer with `can_manage_roles` permission): can manage assignments.
- **Officer** (anyone with police job): receives roles; gains access to gated doors/stashes accordingly.

## Stack
- Lua 5.4 FiveM resource
- qbx_core, ox_lib, ox_inventory, ox_doorlock, ox_target, oxmysql
- MySQL tables: `police_role_definitions`, `police_roles`

## Implemented (v1.0.0)
- DB schema auto-install + default role seeding (chief, captain, lieutenant, sergeant, officer, cadet, swat, k9, detective, traffic).
- Role assignment / removal / creation / deletion via ox_lib context menu (`/policeadmin`) and chat commands (`/policegive`, `/policetake`).
- Duty system (`/duty`) + `/myroles` self-view.
- Door gating: listens to `ox_doorlock:setState`, re-locks if player lacks role.
- Stash gating: registers stashes with ox_inventory, ox_target prompts to open, server verifies role + duty before opening.
- Permission flags (`can_manage_roles`, `can_assign_role`, `can_remove_role`, `can_create_role`, `access_all`).
- Server exports + ox_lib callbacks for other scripts to query.
- English locale file.

## Backlog (P1/P2 — not yet implemented)
- P1: Offline player role management (lookup by citizenid via DB even if offline).
- P1: MDT-style NUI panel (HTML/CSS) as alternative to ox_lib menu.
- P2: Audit log table (`police_role_log`) of every assign/remove with timestamp.
- P2: Per-role payroll multiplier hook into qbx_management/banking.
- P2: Per-role wardrobe/garage gating.
- P2: Discord webhook on role create/assign/remove.
- P2: Additional locales (es, de, fr, nl).

## Notes
- This is a FiveM Lua resource, not a web app. No backend/frontend testing applicable in this environment — must be tested on a live FiveM server with qbox + ox installed.
