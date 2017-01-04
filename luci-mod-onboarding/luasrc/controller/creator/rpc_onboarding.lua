#!/usr/bin/lua
module("luci.controller.creator.rpc_onboarding", package.seeall)

function index()

	local rpc = node("rpc")

	rpc.notemplate = true

	entry({"rpc", "creator_onboarding"}, call("rpc_creator"))

end

function rpc_creator()
	local creator  = require "luci.jsonrpcbind.creator.onboarding"
	local jsonrpc = require "luci.jsonrpc"
	local http    = require "luci.http"
	local ltn12   = require "luci.ltn12"

	http.prepare_content("application/json")
	ltn12.pump.all(jsonrpc.handle(creator, http.source()), http.write)
end
