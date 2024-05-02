
local Discord = {}
local Players = {}

local Token <const> = ("Bot %s"):format(GetConvar("discord:token", ""))
local Errors <const> = json.decode(LoadResourceFile(GetCurrentResourceName(), "errors.json"))

local Data <const> = {
    ["Authorization"] = Token, 
    ["X-Audit-Log-Reason"] = "Grm Discord v2!",
    ['Content-Type'] = 'application/json'
}

---@param method string
---@param endpoint string
---@param jsondata table
---@return any
function Discord.Request(method, endpoint, jsondata)
    local p = promise.new()

    local u = "https://discordapp.com/api/%s"
    local c = function(...) p:resolve({ ... }) end

    PerformHttpRequest(u:format(endpoint), c, method, jsondata or "", Data)

    local c, r, h = table.unpack(Citizen.Await(p))
    
    if c ~= 200 and c ~= 204 then return error(Errors[c]) end
    
    return r, h
end

---@param source number
---@return number|nil
function Discord.GetUserId(source)
    local license <const> = GetPlayerIdentifierByType(source, "discord")
    return license and license:gsub("discord:", "") or nil
end

local Guild <const> = GetConvar("discord:guild", "") 

---@return table
function Discord.GetGuild()
    return Discord.Request("GET", ("guilds/%s"):format(Guild))
end

exports("GetGuild", Discord.GetGuild)

---@param source number
---@param refresh boolean
---@return table|nil
function Discord.GetUser(source, refresh)
    local id = Discord.GetUserId(source)
   
    if not id then return warn(("player.%s does not have a discord account linked!"):format(source)) end

    if not refresh and Players[id] then return Players[id] end

    local result = Discord.Request("GET", ("guilds/%s/members/%s"):format(Guild, id))

    if not result then return warn(("player.%s is not inside server.%s"):format(source, Guild)) end

    result = json.decode(result)

    local file = (result.user.avatar:sub(1, 1) and result.user.avatar:sub(2, 2) == "_") and "gif" or "png"
    result.user.avatar = ("https://cdn.discordapp.com/avatars/%s/%s.%s"):format(id, result.user.avatar, file)
    
    local d, m, y = result.joined_at:sub(9, 10), result.joined_at:sub(6,7), result.joined_at:sub(1,4)
    result.joined_at = ("%s/%s/%s"):format(d, m, y)

    local user = table.clone(result.user)   
    result.user = nil

    for key, val in pairs(user) do result[key] = val end

    Players[id] = result

    return result
end

exports("GetUser", Discord.GetUser)

---@param source number
---@param nickname string
---@return boolean|nil
function Discord.SetNickname(source, nickname)
    local id = Discord.GetUserId(source)

    if not id then return warn(("player.%s does not have a discord account linked!"):format(source)) end

    Discord.Request("PATCH", ("guilds/%s/members/%s"):format(Guild, id), json.encode({ nick = tostring(nickname) }))
    
    if Players[id] then Players[id].nick = nickname end

    return true
end

exports("SetNickname", Discord.SetNickname)

---@param source number
---@param reason string
---@return boolean|nil
function Discord.BanUser(source, reason)
    local id = Discord.GetUserId(source)

    if not id then return warn(("player.%s does not have a discord account linked!"):format(source)) end

    Discord.Request("PUT", ("guilds/%s/bans/%s"):format(Guild, id), json.encode({reason = tostring(reason)}))

    Players[id] = nil

    return true
end

exports("BanUser", Discord.BanUser)

---@return table
function Discord.GetGuildRoles()
    local result = Discord.Request("GET", ("guilds/%s/roles"):format(Guild))

    if not result then return warn(("Failed to retrieve roles from server %s."):format(source, Guild)) end

    result = json.decode(result)
    
    return result
end

exports("GetGuildRoles", Discord.GetGuildRoles)

---@param source number
---@param role string|string[]
---@return table|nil
function Discord.HaveRole(source, role)
    local id = Discord.GetUserId(source)

    if not id then return warn(("player.%s does not have a discord account linked!"):format(source)) end

    local roles = Players[id]?.roles or Discord.GetUser(source, true)?.roles

    if not roles then return warn(("Could not find roles for player.%s"):format(source)) end 

    role = type(role) ~= "table" and { role } or role 

    local result = {}

    for i = 1, #role do 
        result[tostring(role[i])] = lib.table.contains(roles, tostring(role[i]))
    end

    return result
end

exports("HaveRole", Discord.HaveRole)

---@param source number
---@param role string|string[]
---@return boolean|nil
function Discord.AddRole(source, role)
    local id = Discord.GetUserId(source)

    if not id then return warn(("player.%s does not have a discord account linked!"):format(source)) end

    local roles = Players[id]?.roles or Discord.GetUser(source, true)?.roles

    if not roles then return warn(("Could not find roles for player.%s"):format(source)) end 

    role = type(role) ~= "table" and { role } or role 

    for _, val in pairs(role) do table.insert(roles, val) end

    Discord.Request('PATCH', ('guilds/%s/members/%s'):format(Guild, id), json.encode({ roles = roles }))

    return true
end

exports("AddRole", Discord.AddRole)

---@param source number
---@param role string|string[]
---@return boolean|nil
function Discord.RemoveRole(source, role)
    local user = Discord.GetUser(source, true)

    if not user?.roles then return warn(("Could not find roles for player.%s"):format(source)) end 
    
    role = type(role) ~= "table" and { role } or role 

    for i, v in ipairs(user.roles) do if lib.table.contains(role, v) then table.remove(user.roles, i) end end

    Discord.Request('PATCH', ('guilds/%s/members/%s'):format(Guild, user.id), json.encode({ roles = user.roles }))

    return true
end

exports("RemoveRole", Discord.RemoveRole)

---@param role string|string[]
---@return table
function Discord.GetRoleInfo(role)
    role = type(role) ~= "table" and { role } or role 

    for i = 1, #role do role[i] = tostring(role[i]) end -- prevent issues

    local result = Discord.Request('GET', ('guilds/%s/roles'):format(Guild))
    
    result = json.decode(result)

    local roles = {}

    for i, val in pairs(result) do
        roles[val.id] = lib.table.contains(role, val.id) and val or nil
    end

    return roles
end

exports("GetRoleInfo", Discord.GetRoleInfo)