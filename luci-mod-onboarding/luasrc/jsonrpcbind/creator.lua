#!/usr/bin/lua

module("luci.jsonrpcbind.creator", package.seeall)
local creatorOnboarding = require "creator.onboarding"

function isProvisioned()
    return creatorOnboarding.isOnboardingCompleted()
end

function unProvision()
    return creatorOnboarding.unProvision()
end

function boardName()
    return creatorOnboarding.getBoardName()
end

function doOnboarding(...)
    return creatorOnboarding.doOnboarding(...)
end

function boardInfo()
    return creatorOnboarding.getBoardInfo()
end
