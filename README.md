# How to use certificate/PSK generation scripts with ubus/rpc.

## Prerequisites

You must install following packages on CI40:

	opkg install curl luci-mod-rpc libubox-lua


## Certificate/PSK generation via RPC

`imgtec_generate` is main script to generate certificate or PSK.
It has following parameters:
1. 'cert' / 'psk'
2. device server url
3. key to device server
4. secret to device server

It contacts device server to generate certificate/PSK, which is returned in two ways:
via standard output (which is used through RPC) and send by ubus event.

IMPORTANT:
Calling 'imgtec_generate' with 'cert' parameter will generate certificate ('cert.pem')
and provisioning configuration ('provisioning.cfg') files and store on the
file system (default location is '/root/' directory').

## Using generation script through RPC

On CI40 board there's [luci JSON-RPC mechanism](http://luci.subsignal.org/trac/wiki/Documentation/JsonRpcHowTo).
First you have to authenticate on the CI40 by sending

    curl -i -X POST -d '{"method": "login", "params": ["root", "password"]}' http://<YOUR_IP>/cgi-bin/luci/rpc/auth

This will return token.

Then you just call

    curl -i -X POST -d '{"method": "exec", "params": ["/root/imgtec_generate cert https://deviceserver.flowcloud.systems YOUR_KEY YOUR_SECRET"], "id": 111}' http://<YOUR_IP>/cgi-bin/luci/rpc/sys\?auth\=RETURNED_TOKEN    


To receive PSK call

    curl -i -X POST -d '{"method": "exec", "params": ["/root/imgtec_generate psk https://deviceserver.flowcloud.systems"], "id": 111}' http://<YOUR_IP>/cgi-bin/luci/rpc/sys\?auth\=RETURNED_TOKEN


## Using generation script through ubus

### Running ubus service

To expose generation methods in ubus interface, run `imgtec_generate_ubus` script.
Now you check if ubus service for cert/psk generation is up and running:

    ubus -v list imgtec

You should receive something like

```
'imgtec' @2137ca11
	"generateCert":{"id":"Integer","msg":"String"}
	"generatePsk":{"id":"Integer","msg":"String"}
```

### Cert generation through ubus

Now you could generate certificate:

	ubus call imgtec generateCert '{"ds_url": "https://deviceserver.flowcloud.systems", "key": "YOUR_KEY", "secret": "YOUR_SECRET}'

Response will be returned with a generated `certificate`.
In case of an error json response is send in following format '{error_msg = "ERROR_CAUSE"}'.

### PSK generation through ubus

For PSK generation, you need key and secret to Device Server stored in `/root/provisioning.cfg` file in following json format:

    {"url"="DEVICE_SERVER_URL", "key": "YOUR_KEY", "secret": "YOUR_SECRET"}

Which means that you must go through 'generate cert' procedure first.

Then you could generate PSK:

	ubus call imgtec generatePsk '{}'

In case of an error json response is send in following format '{error_msg = "ERROR_CAUSE"}'.

### Starting ubus service as [daemon](https://wiki.openwrt.org/doc/techref/initscripts)

Copy `imgtec_ubus` to `/etc/init.d/imgtec_ubus`.

In order to automatically start the init script on boot, it must be installed into `/etc/rc.d/`.
Invoke the "enable" command to run the initscript on boot: `/etc/init.d/imgtec_ubus enable`.

All `imgtec_generate*` scripts should be present in `/root`.

1. `imgtec_generate_ubus`: listen for ubus call command
2. `imgtec_generate`: called by `imgtec_generate_ubus` to generate certificate/psk

To start daemon manually, call `/etc/init.d/imgtec_ubus start`.
