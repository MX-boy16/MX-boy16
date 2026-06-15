Utils = {}

function Utils.L(key, ...)
    local locale = Locales[(Config and Config.Locale) or 'en']
    local str = (locale and locale[key]) or key
    if select('#', ...) > 0 then
        return string.format(str, ...)
    end
    return str
end

function Utils.dprint(...)
    if Config.Debug then
        print('[dusa_mechanic]', ...)
    end
end

function Utils.round(num, dec)
    local m = 10 ^ (dec or 0)
    return math.floor(num * m + 0.5) / m
end

function Utils.getShopById(id)
    for _, s in ipairs(Config.Shops) do
        if s.id == id then return s end
    end
end

function Utils.tableContains(tbl, val)
    for _, v in ipairs(tbl) do
        if v == val then return true end
    end
    return false
end
