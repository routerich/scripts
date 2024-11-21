#!/bin/sh

wget --no-check-certificate -O /tmp/uninstall.sh https://raw.githubusercontent.com/gSpotx2f/ruantiblock_openwrt/master/autoinstall/2.x/uninstall.sh && chmod +x /tmp/uninstall.sh && printf '%s\n' Y | /tmp/uninstall.sh

wget --no-check-certificate -O /tmp/autoinstall.sh https://raw.githubusercontent.com/gSpotx2f/ruantiblock_openwrt/master/autoinstall/2.x/autoinstall.sh && chmod +x /tmp/autoinstall.sh && printf '%s\n' 2 2 Y Y Y | /tmp/autoinstall.sh

opkg install unzip sing-box

cat <<'EOF' > /etc/init.d/vpn
#!/bin/sh /etc/rc.common
# Copyright (C) 2011 OpenWrt.org

USE_PROCD=1
START=40
STOP=89
PROG=/usr/bin/vpns
start_service() {
        procd_open_instance
        procd_set_param command "$PROG" -verbosity 50
        procd_set_param stdout 1
        procd_set_param stderr 1
        procd_set_param respawn ${respawn_threshold:-3600} ${respawn_timeout:-5} ${respawn_retry:-5}
        procd_close_instance
}
EOF

chmod +x /etc/init.d/vpn

url="https://github.com/Snawoot/opera-proxy/releases/download/v1.6.0/opera-proxy.linux-arm64"
destination_file="/usr/bin/vpns"

echo "Uploading a file..."
wget "$url" -O "$destination_file" || { echo "Failed to download the file"; exit 1; }
echo "Adding execution permission..."
chmod +x "$destination_file" || { echo "Failed to add execution permission"; exit 1; }
echo "The file was successfully downloaded and moved to $destination_file"

cat <<EOF > /etc/sing-box/config.json
  {
    "log": {
  	"disabled": true,
  	"level": "error"
  },
  "inbounds": [
    {
      "type": "tproxy",
      "listen": "::",
      "listen_port": 1100,
      "sniff": false
    }
  ],
  "outbounds": [
    {
      "type": "http",
      "server": "127.0.0.1",
      "server_port": 18080
    }
  ],
  "route": {
    "auto_detect_interface": true
  }
}
EOF

echo "Setting sing-box"
uci set sing-box.main.enabled='1'
uci set sing-box.main.user='root'
uci commit sing-box


echo "Configuring Ruantiblock"
uci set ruantiblock.config.proxy_mode='3'
uci set ruantiblock.config.t_proxy_type='1'
uci set ruantiblock.config.bllist_preset='ruantiblock-fqdn'
uci commit ruantiblock


echo "Launching services"
service vpn enable
service vpn restart
service sing-box enable
service sing-box restart
service ruantiblock enable
service ruantiblock restart
ruantiblock update
