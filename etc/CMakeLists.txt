# Add install targets
######################
INSTALL(PROGRAMS init.d/creator_device_server_ubus_appd DESTINATION /etc/init.d/)
INSTALL(FILES avahi/services/ci40.onboarding.service DESTINATION /etc/avahi/services)
