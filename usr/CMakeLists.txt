# Add install targets
######################
INSTALL( DIRECTORY lib/ DESTINATION /usr/lib/ )
INSTALL(PROGRAMS bin/creator_device_server_ubus_appd DESTINATION /usr/bin/)
