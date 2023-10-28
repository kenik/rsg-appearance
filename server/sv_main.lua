local RSGCore = exports['rsg-core']:GetCoreObject()

-----------------------------------------------------------------------
-- version checker
-----------------------------------------------------------------------
local function versionCheckPrint(_type, log)
    local color = _type == 'success' and '^2' or '^1'

    print(('^5['..GetCurrentResourceName()..']%s %s^7'):format(color, log))
end

local function CheckVersion()
    PerformHttpRequest('https://raw.githubusercontent.com/Rexshack-RedM/rsg-appearance/main/version.txt', function(err, text, headers)
        local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version')

        if not text then 
            versionCheckPrint('error', 'Currently unable to run a version check.')
            return 
        end

        --versionCheckPrint('success', ('Current Version: %s'):format(currentVersion))
        --versionCheckPrint('success', ('Latest Version: %s'):format(text))
        
        if text == currentVersion then
            versionCheckPrint('success', 'You are running the latest version.')
        else
            versionCheckPrint('error', ('You are currently running an outdated version, please update to version %s'):format(text))
        end
    end)
end

-----------------------------------------------------------------------

RegisterServerEvent('rsg-appearance:SaveSkin')
AddEventHandler('rsg-appearance:SaveSkin', function(skin)
    local _skin = skin
    local _source = source
    local encode = json.encode(_skin)
    local Player = RSGCore.Functions.GetPlayer(source)
    local citizenid = Player.PlayerData.citizenid
    local license = RSGCore.Functions.GetIdentifier(source, 'license')
    TriggerEvent("rsg-appearance:retrieveSkin", citizenid, license, function(call)
        if call then
            MySQL.Async.execute("UPDATE playerskins SET `skin` = ? WHERE `citizenid`= ? AND `license`= ?", {encode, citizenid, license})
        else
            MySQL.Async.insert('INSERT INTO playerskins (citizenid, license, skin) VALUES (?, ?, ?);', {citizenid, license, encode})
        end
    end)
    TriggerClientEvent('rsg-spawn:client:setupSpawnUI', source, encode, true)
end)

RegisterServerEvent('rsg-appearance:SetPlayerBucket')
AddEventHandler('rsg-appearance:SetPlayerBucket', function(b)
   SetPlayerRoutingBucket(source, b)
end)

RegisterServerEvent('rsg-appearance:LoadSkin')
AddEventHandler('rsg-appearance:LoadSkin', function()
    local _source = source
    local User = RSGCore.Functions.GetPlayer(source)
    local citizenid = User.PlayerData.citizenid
    local license = RSGCore.Functions.GetIdentifier(source, 'license')
    local skins = MySQL.Sync.fetchAll('SELECT * FROM playerskins WHERE citizenid = ? AND license = ?', {citizenid, license})
    if skins[1] then
        local skin = skins[1].skin
        local decoded = json.decode(skin)
        TriggerClientEvent("rsg-appearance:ApplySkin", _source, decoded)
    else
        TriggerClientEvent("rsg-appearance:OpenCreator", _source)
    end
end)

AddEventHandler('rsg-appearance:retrieveSkin', function(citizenid, license, callback)
    local Callback = callback
    local skins = MySQL.Sync.fetchAll('SELECT * FROM playerskins WHERE citizenid = ? AND license = ?', {citizenid, license})
    if skins[1] then
        Callback(skins[1])
    else
        Callback(false)
    end
end)

RegisterServerEvent("rsg-appearance:deleteSkin")
AddEventHandler("rsg-appearance:deleteSkin", function(license, Callback)
    local _source = source
    local id
    for k, v in ipairs(GetPlayerIdentifiers(_source)) do
        if string.sub(v, 1, string.len("steam:")) == "steam:" then
            id = v
            break
        end
    end
    local Callback = callback
    MySQL.Async.fetchAll('DELETE FROM playerskins WHERE `citizenid`= ? AND`license`= ?;', {id, license})
end)

RegisterServerEvent('rsg-appearance:updategender', function(gender)
    local Player = RSGCore.Functions.GetPlayer(source)
    local citizenid = Player.PlayerData.citizenid
    local license = RSGCore.Functions.GetIdentifier(source, 'license')

    local result = MySQL.Sync.fetchAll('SELECT * FROM players WHERE citizenid = ? AND license = ?', {citizenid, license})
    local Charinfo = json.decode(result[1].charinfo)
    Charinfo.gender = gender
    MySQL.Async.execute("UPDATE players SET `charinfo` = ? WHERE `citizenid`= ? AND `license`= ?", {json.encode(Charinfo), citizenid, license})
end)

--------------------------------------------------------------------------------------------------
-- start version check
--------------------------------------------------------------------------------------------------
CheckVersion()
