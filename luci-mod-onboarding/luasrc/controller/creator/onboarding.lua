#!/usr/bin/lua
module("luci.controller.creator.onboarding", package.seeall)

local ubus = require "ubus"
local ds = require("creator.ds")
local onboarding = require("creator.onboarding")

local conn = ubus.connect();

function index()
    entry({"admin", "creator"}, call("creator_onboarding"), "Creator", 50).dependent=false
    entry({"admin", "creator", "onboarding"}, call("onboarding_index"), "Onboarding", 1).dependent=false
    entry({"admin", "creator", "onboarding", "idp_login"}, call("idp_login"), nil, nil).dependent=false
    entry({"admin", "creator", "onboarding", "form"}, call("form"), nil, nil).dependent=false
    entry({"admin", "creator", "onboarding", "start_onboarding"}, call("start_onboarding"), nil, nil).dependent=false
    entry({"admin", "creator", "onboarding", "unprovision"}, call("unprovision"), nil, nil).dependent=false
    entry({"admin", "creator", "onboarding", "idp_login_completed"}, call("idp_login_completed"), nil, nil).dependent=false
    entry({"admin", "creator", "onboarding", "idp_login_completed2"}, call("idp_login_completed2"), nil, nil).dependent=false
end

function onboarding_index()
    if onboarding.isOnboardingCompleted() then
        luci.template.render("creator_onboarding/onboarding_completed")
    else
        luci.template.render("creator_onboarding/onboarding_info")
    end
end

function idp_login()
    luci.http.prepare_content("text/html")
    local url = "https://id.creatordev.io/oauth2/auth"
    local client_id = "2fcb0129-4354-4520-af54-8e3017b8e1f6"
    local scope = "core+openid+offline"
    local redirectUri = "https://OpenWrt.local/cgi-bin/luci/admin/creator/onboarding/idp_login_completed"
    local state = "dummy_state"
    local response_type = "id_token"
    local nonce = "ABCDEFGH"

    luci.http.redirect(url .. "?client_id=" .. client_id .. "&scope=" .. scope .. "&redirectUri=" .. redirectUri .. "&state=" .. state .. "&response_type=" .. response_type .. "&nonce=" .. nonce)
end

function form()
    local token = luci.http.formvalue("token")
    local key, secret = ds.getKeyAndSecret("https://developer-id.flowcloud.systems", token)
    luci.template.render("creator_onboarding/onboarding_form", {key = key, secret = secret, ds_url = "https://deviceserver.creatordev.io"})
end

-- Ajax functions --

function start_onboarding()
    local ds_url = tostring(luci.http.formvalue("ds_url"))
    local key = tostring(luci.http.formvalue("key"))
    local secret = tostring(luci.http.formvalue("secret"))
    local name = tostring(luci.http.formvalue("secret"))
    local ok, err = pcall(onboarding.doOnboarding, ds_url, key, secret, name)
    if not ok then
        luci.http.status(500, err.msg);
    else
        luci.http.status(200, "OK");
    end
end

function start_onboarding()
    local ds_url = tostring(luci.http.formvalue("ds_url"))
    local key = tostring(luci.http.formvalue("key"))
    local secret = tostring(luci.http.formvalue("secret"))
    local endPointName = tostring(luci.http.formvalue("endPointName"))
    local ok, err = pcall(onboarding.doOnboarding, ds_url, key, secret, endPointName)
    if not ok then
        luci.http.status(500, err.msg);
    else
        luci.http.status(200, endPointName);
    end
end

function unprovision()
    if onboarding.unProvision() then
        luci.http.status(200, "OK")
    else
        luci.http.status(500, "Couldn't do unprovisioning of this Ci40 board")
    end
end

function idp_login_completed()
    local token = luci.http.formvalue("token")
    if token == nil then
        luci.template.render("creator_onboarding/idp_login_completed")
    else
        luci.http.redirect(luci.dispatcher.build_url("admin", "creator", "onboarding", "form") .. "?token=" .. token)
    end
end

function idp_login_completed2()
    local token = luci.http.formvalue("id_token")
    local key, secret = ds.getKeyAndSecret("https://developer-id.flowcloud.systems", token)
    luci.template.render("creator_onboarding/idp_login_completed", {key = key, secret = secret})
end

function isBoardConnectedToDeviceServer()
    return ds.getClients()
end
