# Project Properties
####################
CMAKE_MINIMUM_REQUIRED (VERSION 2.6.2)

PROJECT(onboarding-scripts)

# Options
###################
SET(CMAKE_VERBOSE_MAKEFILE 1)
SET(CMAKE_BUILD_TYPE DEBUG)

# Paths
########
ADD_SUBDIRECTORY(etc)
ADD_SUBDIRECTORY(usr)
ADD_SUBDIRECTORY(luci-mod-onboarding)
