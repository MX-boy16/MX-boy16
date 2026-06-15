-- shared helpers (config + db merged role list lives server-side, this file is helpers only)
Shared = Shared or {}

---Returns true if any value in `list` equals `needle`. Case-insensitive on strings.
function Shared.contains(list, needle)
    if type(list) ~= 'table' or needle == nil then return false end
    local n = type(needle) == 'string' and needle:lower() or needle
    for _, v in pairs(list) do
        local cmp = type(v) == 'string' and v:lower() or v
        if cmp == n then return true end
    end
    return false
end

---Intersect: returns true if any role in `playerRoles` matches one in `required`.
function Shared.anyMatch(playerRoles, required)
    if type(required) ~= 'table' or #required == 0 then return false end
    if type(playerRoles) ~= 'table' then return false end
    for _, r in pairs(required) do
        if Shared.contains(playerRoles, r) then return true end
    end
    return false
end

function Shared.normalizeRoleName(name)
    if type(name) ~= 'string' then return nil end
    name = name:gsub('%s+', '_'):lower()
    name = name:gsub('[^%w_]', '')
    if name == '' then return nil end
    return name
end
