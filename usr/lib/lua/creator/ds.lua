#!/usr/bin/lua

-- This module allows to perform various operations on device server

module("creator.ds", package.seeall)

local ubus = require "ubus"
local jsonc = require("luci.jsonc")
local creator_utils = require "creator.utils"
local nixiofs = require('nixio.fs')

local conn = ubus.connect()
if not conn then
  creatorError("Failed to connect to ubus")
end

function generate(ds_url, key, secret, link_name)

  local tmp = "data.tmp"
  if not (ds_url and key and secret) then
    creator_utils.creatorError("Invalid params");
  end

  local op = os.execute("curl -s '"..ds_url.."/oauth/token' -H 'application/json' --data 'username="..key.."&password="..secret.."&grant_type=password' >" ..tmp)
  if (op > 0) then
    creator_utils.creatorError("Unable to get session token form device server");
  end

  local content = creator_utils.fileToString(tmp)

  local data = jsonc.parse(content)
  if data == nil then
      creator_utils.creatorError("Invalid json data returned from server")
  end
  local access_token = data.access_token

  op = os.execute("curl -s '"..ds_url.."' -H 'application/json' -H 'Authorization:Bearer "..access_token.."' >" ..tmp)
  if (op > 0) then
    creator_utils.creatorError("Unable to get session token form device server");
  end
  local content = creator_utils.fileToString(tmp)
  local identities = creator_utils.findLinkForKey(jsonc.parse(content), "identities")
  op = os.execute("curl -s '"..identities.href.."' -H 'application/json' -H 'Authorization:Bearer "..access_token.."' >" ..tmp)
  if (op > 0) then
    creator_utils.creatorError("Unable to reach identities endpoint");
  end
  content = creator_utils.fileToString(tmp)
  local link = creator_utils.findLinkForKey(jsonc.parse(content), link_name)

  op = os.execute("curl -s '"..link.href.."' -X GET -H 'application/json' -H 'Authorization:Bearer "..access_token.."' >" ..tmp)
  if (op > 0) then
    creator_utils.creatorError("Unable to reach " .. link_name .. " endpoint");
  end
  content = creator_utils.fileToString(tmp)
  local add = creator_utils.findLinkForKey(jsonc.parse(content), "add")

  op = os.execute("curl -s '"..add.href.."' -X POST -H 'application/json' -H 'Authorization:Bearer "..access_token.."' >" ..tmp)
  if (op > 0) then
    creator_utils.creatorError("Unable to generate " .. link_name);
  end
  content = creator_utils.fileToString(tmp)

  local result = jsonc.parse(content)
  os.remove(tmp)
  return result
end

function generateCert(ds_url, _key, _secret)
  local ok, certOrError = pcall(generate, ds_url, _key, _secret, "certificate")
  if not ok then
      creator_utils.creatorError("Certificate generation failed : " .. certOrError.msg)
  end
  return certOrError
end

function generatePsk(ds_url, key, secret)
  local ok, pskOrErr = pcall(generate, ds_url, key, secret, "psk")

  if not ok then
    local err_msg = "PSK generation failed : " .. pskOrErr.msg
    creator_utils.creatorError(pskOrErr.msg)
  end
  return pskOrErr
end

function getKeyAndSecret(account_server_url, id_token)
    local tmp = "data.tmp"
    local op = os.execute("curl -s '" .. account_server_url .. "' -H 'application/json' --data 'id_token=" .. id_token .. "' >" .. tmp)
    local resp = creator_utils.loadJsonFromFile(tmp)

    os.remove(tmp)
    return resp.Key, resp.Secret
end

function getClients(ds_url, key, secret)

    local tmp = "data.tmp"

    local op = os.execute("curl -s '"..ds_url.."/oauth/token' -H 'application/json' --data 'username="..key.."&password="..secret.."&grant_type=password' >" ..tmp)
    if (op > 0) then
      return nil
    end

    local content = creator_utils.fileToString(tmp)

    local data = jsonc.parse(content)

    if data == nil then
        return nil
    end
    local access_token = data.access_token

    op = os.execute("curl -s '"..ds_url.."' -H 'application/json' -H 'Authorization:Bearer "..access_token.."' >" ..tmp)
    if (op > 0) then
      return nil
    end
    local content = creator_utils.fileToString(tmp)
    local clients = creator_utils.findLinkForKey(jsonc.parse(content), "clients")
    op = os.execute("curl -s '"..clients.href.."' -H 'application/json' -H 'Authorization:Bearer "..access_token.."' >" ..tmp)
    if (op > 0) then
      return nil
    end
    local clients = jsonc.parse(creator_utils.fileToString(tmp))
    if (clients.Items == nil) then
        return nil
    end

    local clientsArr = {}

    for i = 1, #clients.Items do
        table.insert(clientsArr, clients.Items[i].Name)
    end
    return clientsArr

end
