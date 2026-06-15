-- Hooks into ox_doorlock so doors gated by this script are unlockable
-- ONLY by players whose police_roles match config requirements.
--
-- Strategy: ox_doorlock fires an event `ox_doorlock:setState` from the client
-- after passing its own group/item check. We additionally subscribe to its
-- server event that fires *before* state change. ox_doorlock supports
-- "customCheck" only client-side. To keep this independent we instead expose
-- a callback (`qbx_policeroles:doorAccess`) the client calls before requesting
-- ox_doorlock to toggle. See client/doors.lua for the corresponding logic.
--
-- This file additionally exposes a helper event that other scripts can fire
-- when ox_doorlock attempts a state change, allowing centralised logging.

RegisterNetEvent('qbx_policeroles:logDoorUnlock', function(doorId, allowed)
    local src = source
    local cid = Roles.GetCitizenId(src) or ('src:' .. src)
    print(('^3[qbx_policeroles]^7 door=%s by=%s allowed=%s'):format(tostring(doorId), cid, tostring(allowed)))
end)
