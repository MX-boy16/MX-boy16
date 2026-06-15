DB = {}

local function jsonEncode(t)
    return json.encode(t or {})
end

local function jsonDecode(s)
    if not s or s == '' then return {} end
    local ok, res = pcall(json.decode, s)
    if ok and type(res) == 'table' then return res end
    return {}
end

---Installs SQL schema and seeds the default role definitions.
function DB.Install()
    local schemaFile = LoadResourceFile(GetCurrentResourceName(), 'sql/install.sql')
    if not schemaFile then
        print('^1[qbx_policeroles]^7 Could not read sql/install.sql')
        return
    end

    for stmt in schemaFile:gmatch('([^;]+);') do
        local trimmed = stmt:gsub('^%s+', ''):gsub('%s+$', '')
        if trimmed ~= '' then
            MySQL.query.await(trimmed)
        end
    end

    -- Seed defaults (do not overwrite if admin has edited)
    for _, role in ipairs(Config.DefaultRoles) do
        MySQL.insert.await([[
            INSERT INTO police_role_definitions (name, label, description, permissions, is_default, created_by)
            VALUES (?, ?, ?, ?, 1, 'SYSTEM')
            ON DUPLICATE KEY UPDATE
                label = IF(is_default = 1, VALUES(label), label),
                description = IF(is_default = 1, VALUES(description), description),
                permissions = IF(is_default = 1, VALUES(permissions), permissions)
        ]], {
            role.name,
            role.label,
            role.description or '',
            jsonEncode(role.permissions or {}),
        })
    end

    print('^2[qbx_policeroles]^7 Database installed and defaults seeded.')
end

---Returns all role definitions (config defaults + DB custom merged), keyed by name.
function DB.GetAllRoleDefinitions()
    local rows = MySQL.query.await('SELECT name, label, description, permissions, is_default FROM police_role_definitions') or {}
    local out = {}
    for _, row in ipairs(rows) do
        out[row.name] = {
            name        = row.name,
            label       = row.label,
            description = row.description or '',
            permissions = jsonDecode(row.permissions),
            is_default  = row.is_default == 1,
        }
    end
    return out
end

function DB.GetRoleDefinition(name)
    local row = MySQL.single.await(
        'SELECT name, label, description, permissions, is_default FROM police_role_definitions WHERE name = ?',
        { name }
    )
    if not row then return nil end
    return {
        name        = row.name,
        label       = row.label,
        description = row.description or '',
        permissions = jsonDecode(row.permissions),
        is_default  = row.is_default == 1,
    }
end

function DB.CreateRole(name, label, description, permissions, createdBy)
    local ok = MySQL.insert.await([[
        INSERT INTO police_role_definitions (name, label, description, permissions, is_default, created_by)
        VALUES (?, ?, ?, ?, 0, ?)
    ]], { name, label, description or '', jsonEncode(permissions or {}), createdBy or 'unknown' })
    return ok and ok > 0
end

function DB.DeleteRole(name)
    local affected = MySQL.update.await('DELETE FROM police_role_definitions WHERE name = ? AND is_default = 0', { name })
    return affected and affected > 0
end

---Returns list of role names (strings) granted to citizenid.
function DB.GetPlayerRoles(citizenid)
    local rows = MySQL.query.await('SELECT role FROM police_roles WHERE citizenid = ?', { citizenid }) or {}
    local out = {}
    for _, r in ipairs(rows) do out[#out + 1] = r.role end
    return out
end

function DB.AssignRole(citizenid, role, grantedBy)
    local id = MySQL.insert.await([[
        INSERT IGNORE INTO police_roles (citizenid, role, granted_by) VALUES (?, ?, ?)
    ]], { citizenid, role, grantedBy or 'unknown' })
    return id and id > 0
end

function DB.RemoveRole(citizenid, role)
    local affected = MySQL.update.await(
        'DELETE FROM police_roles WHERE citizenid = ? AND role = ?',
        { citizenid, role }
    )
    return affected and affected > 0
end

function DB.RemoveAllRoles(citizenid)
    return MySQL.update.await('DELETE FROM police_roles WHERE citizenid = ?', { citizenid }) or 0
end
