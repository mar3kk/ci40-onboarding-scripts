#!/usr/bin/lua

module("creator.onboarding", package.seeall)

local creator_utils = require "creator.utils"
local creator_ds = require "creator.ds"
local jsonc = require "luci.jsonc"
local nixiofs = require "nixio.fs"

function doOnboarding(ds_url, _key, _secret, _clientName)
  local ok, certOrError = pcall(creator_ds.generateCert, ds_url, _key, _secret, "certificate")
  if not ok then
    creator_utils.creatorError(certOrError.msg)
  else
    nixiofs.mkdirr("/etc/creator")
    creator_utils.stringTofile("/etc/creator/endpoint.crt", certOrError.RawCertificate)
    creator_utils.stringTofile("/etc/creator/provisioning.cfg", jsonc.stringify({url=ds_url, key = _key, secret = _secret}))
    if (_clientName ~= nil) then
      creator_utils.stringTofile("/etc/creator/endPointName", string.format("ENDPOINT_NAME=%s", _clientName))
    end
    luci.sys.exec("/etc/init.d/awa_clientd restart")
    return true
  end
end

function isOnboardingCompleted()
    return nixiofs.stat("/etc/creator/endpoint.crt", 'type') == 'reg'
end

function unProvision()
     nixiofs.unlink("/etc/creator/endpoint.crt")
     if isOnboardingCompleted() then
         return false
     else
         luci.sys.exec("/etc/init.d/awa_clientd restart")
         return true
     end
end

function getBoardName()
    local content = creator_utils.fileToString("/etc/creator/endPointName")
    if (content == nil) then
        content = "Not Set"
    else
        content = content:gsub("ENDPOINT_NAME=", "")
    end
    return content
end

function getBoardInfo()
  local hostname = luci.model.uci.cursor():get_first("system", "system", "hostname")
  local wireless = luci.model.uci.cursor():get_all("wireless", "sta")
  local out = {host = hostname, wireless = wireless}
  return out
end

local function getConfig()
    return jsonc.parse(creator_utils.fileToString("/etc/creator/provisioning.cfg"))
end

function isBoardConnectedToDeviceServer()
    local config = getConfig()
    if (config == nil) then
        return false
    end

    local boardName = getBoardName()
    if (boardName == nil) then
        return false
    end

    local clients = creator_ds.getClients(config.url, config.key, config.secret)
    if clients == nil then
        return false
    end
    for i = 1, #clients do
        if (clients[i] == boardName) then
            return true
        end
    end

    return false
end
