# Dusa Mechanic for QBX + OX — PRD

## Original Problem Statement
"Make me a similar mechanic system like dusa_mechanics for FiveM using OX and QBX"

## User Choices
- Framework: QBX Core + ox_lib + ox_target + ox_inventory + oxmysql
- Features: All 8 modules (repair, tuning, cosmetics, NOS, lifts, job/society, towing, diagnostic)
- UI: Custom NUI (modern, branded)
- Locations: Multiple configurable shops
- Database: oxmysql / MySQL

## Architecture
- FiveM resource located at `/app/dusa_mechanic_qbx/`
- Lua client + server scripts split by feature
- Custom NUI in `html/` (vanilla HTML/CSS/JS, no build step)
- MySQL schema in `sql/install.sql` (3 tables: vehicles, logs, society)
- Landing page at `/app/frontend/` previews the NUI in an iframe + ZIP download

## What's Implemented (2026-02-15)
- 27 files, ~100 KB resource
- fxmanifest.lua, config.lua with prices/durations/shops
- Server callbacks for all charges (server-validated)
- Client modules: repair, tuning, cosmetics, NOS (with LSHIFT boost), lifts (3D prop animation), towing, diagnostic, job
- NUI: 5 tabs (Repair / Performance / Visual / NOS / Diagnostic), animated NOS bottle, level bars, color pickers, in-game NOS HUD
- Boss menu with society balance, hire/fire/promote, deposit/withdraw
- ox_target zones for boss, duty, stash, lifts
- Multiple shops out of the box (Strawberry LSC, Burton LSC)
- ZIP download endpoint and live iframe preview on the landing page
- Demo mode in NUI auto-opens for browser preview

## Personas
- Server owner: drops resource into `resources/[scripts]/`, runs SQL, configures jobs/items
- Mechanic player: goes on duty, uses lifts, repairs cars, gets paid via society
- Customer player: drives onto lift, uses self-service NUI (if RequireJob=false) or pays mechanic

## Backlog
- P1: Convert NUI to React build (vite/craco) for true component reuse — currently vanilla JS
- P1: Persistent vehicle state (mods saved to qbx_vehicles instead of in-memory)
- P2: Vehicle delivery missions for mechanic boss
- P2: Discord webhook on big transactions (society > X)
- P2: Animated weld/spark VFX during repair progress
- P2: i18n for FR/DE/ES locales

## Next Tasks
- Add more locales beyond `en`
- Optional integration with `qbx_vehicles` for persistent mod storage
- Add Discord webhook config for high-value transactions
