-- Job / Boss / Employees
local QBX = exports.qbx_core

lib.callback.register('dusa_mechanic:getEmployees', function(src)
    local player = GetPlayer(src)
    if not player or player.PlayerData.job.name ~= Config.JobName then return {} end
    if not player.PlayerData.job.isboss then return {} end
    local res = MySQL.query.await([[
        SELECT citizenid, charinfo, job FROM players
        WHERE JSON_EXTRACT(job, '$.name') = ?
    ]], { Config.JobName })
    local list = {}
    for _, row in ipairs(res or {}) do
        local ci = json.decode(row.charinfo or '{}') or {}
        local jb = json.decode(row.job or '{}') or {}
        list[#list+1] = {
            citizenid = row.citizenid,
            name      = (ci.firstname or '') .. ' ' .. (ci.lastname or ''),
            grade     = (jb.grade and jb.grade.level) or 0,
            gradeName = (jb.grade and jb.grade.name) or 'employee',
        }
    end
    return list
end)

RegisterNetEvent('dusa_mechanic:hire', function(targetSrc)
    local src = source
    local boss = GetPlayer(src)
    if not boss or not boss.PlayerData.job.isboss or boss.PlayerData.job.name ~= Config.JobName then return end
    local target = GetPlayer(targetSrc)
    if not target then return end
    target.Functions.SetJob(Config.JobName, 0)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Hired' })
    TriggerClientEvent('ox_lib:notify', targetSrc, { type = 'success', description = 'You were hired as a mechanic' })
    LogAction(src, 'hire', nil, 0, { target = target.PlayerData.citizenid })
end)

RegisterNetEvent('dusa_mechanic:fire', function(citizenid)
    local src = source
    local boss = GetPlayer(src)
    if not boss or not boss.PlayerData.job.isboss or boss.PlayerData.job.name ~= Config.JobName then return end
    -- find by citizenid (online or offline)
    local target = QBX:GetPlayerByCitizenId(citizenid)
    if target then
        target.Functions.SetJob('unemployed', 0)
        TriggerClientEvent('ox_lib:notify', target.PlayerData.source,
            { type = 'error', description = 'You were fired' })
    else
        MySQL.update([[
            UPDATE players SET job = JSON_SET(job, '$.name', 'unemployed', '$.grade.level', 0, '$.grade.name', 'unemployed')
            WHERE citizenid = ?
        ]], { citizenid })
    end
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Fired' })
    LogAction(src, 'fire', nil, 0, { target = citizenid })
end)

RegisterNetEvent('dusa_mechanic:promote', function(citizenid, grade)
    local src = source
    local boss = GetPlayer(src)
    if not boss or not boss.PlayerData.job.isboss or boss.PlayerData.job.name ~= Config.JobName then return end
    local target = QBX:GetPlayerByCitizenId(citizenid)
    if target then
        target.Functions.SetJob(Config.JobName, grade)
        TriggerClientEvent('ox_lib:notify', target.PlayerData.source,
            { type = 'success', description = 'You were promoted' })
    end
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Promoted' })
end)
