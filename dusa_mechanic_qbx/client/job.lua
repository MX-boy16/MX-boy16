-- =========================================================
-- Client side job helpers (mostly handled in main.lua)
-- =========================================================

RegisterCommand('mechduty', function()
    TriggerServerEvent('dusa_mechanic:toggleDuty')
end, false)
