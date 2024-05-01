# grm-discord v2!
Discord integrations for Fivem

# How to install
- Download the script and drop in the resources folder
- Open your server.cfg and add this: ensure grm-discord
- Go to: https://discord.com/developers/applications
- Create a new bot and invite in your server
- Go back to your server.cfg
- Paste the below with your own bot token & guild id

# Cfg
```
setr discord:token 'token here'
setr discord:guild 'guild id here'
```

# Methods
- Get User Info (avatar, date of join, nickname, etc..)
- Get Guild Info 
- Set Nickname
- Add Roles
- Remove Roles
- Have Roles
- Get Roles Info 


# Some Example's
```lua
    local Discord = exports["grm-discord"]

    ---GetUser
    ---@param source number
    ---@param refresh boolean
    ---@return table|nil
    Discord:GetUser(source, true)

    ---GetGuild
    ---@return table
    Discord:GetGuild()

    ---GetRoleInfo 
    ---@param role string|string[]
    ---@return table
    Discord:GetRoleInfo(source, role)

    ---SetNickname
    ---@param source number
    ---@param nickname string
    ---@return boolean|nil
    Discord:SetNickname(source, newNickname)

    ---AddRole
    ---@param source number
    ---@param role string|string[]
    ---@return boolean|nil
    Discord:AddRole(source, role)

    ---RemoveRole
    ---@param source number
    ---@param role string|string[]
    ---@return boolean|nil
    Discord:RemoveRole(source, role)

    ---HaveRole
    ---@param source number
    ---@param role string|string[]
    ---@return table|nil
    Discord:HaveRole(source, role) 
```