Utils = {}

function Utils.has(tbl, v)
    if not tbl then return false end
    for _, x in ipairs(tbl) do
        if x == v then return true end
    end
    return false
end

function Utils.round(n, dec)
    local m = 10 ^ (dec or 0)
    return math.floor((n or 0) * m + 0.5) / m
end

function Utils.clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

function Utils.dprint(...)
    if Config.Debug then print('[mechanic_tablet]', ...) end
end
