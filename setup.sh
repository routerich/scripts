#!/bin/sh

wget --no-check-certificate -O /tmp/uninstall.sh https://raw.githubusercontent.com/gSpotx2f/ruantiblock_openwrt/master/autoinstall/2.x/uninstall.sh && chmod +x /tmp/uninstall.sh && printf '%s\n' Y | /tmp/uninstall.sh

wget --no-check-certificate -O /tmp/autoinstall.sh https://raw.githubusercontent.com/gSpotx2f/ruantiblock_openwrt/master/autoinstall/2.x/autoinstall.sh && chmod +x /tmp/autoinstall.sh && printf '%s\n' 2 2 Y Y Y | /tmp/autoinstall.sh

opkg install unzip sing-box

echo "Install opera-proxy client"
service stop vpn > /dev/null
rm -f /usr/bin/vpns /etc/init.d/vpn

url="https://github.com/NitroOxid/openwrt-opera-proxy-bin/releases/download/1.6.0/opera-proxy_1.6.0-r1_aarch64_cortex-a53.ipk"
destination_file="/tmp/opera-proxy.ipk"

echo "Downlading opera-proxy..."
wget "$url" -O "$destination_file" || { echo "Failed to download the file"; exit 1; }
echo "Installing opera-proxy..."
opkg install $destination_file

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


echo "Configuring Ruantiblock..."
uci set ruantiblock.config.proxy_mode='3'
uci set ruantiblock.config.t_proxy_type='1'
uci set ruantiblock.config.bllist_preset='ruantiblock-fqdn'

echo "Configuring custom lists..."
uci set ruantiblock.list1.u_proxy_mode='3'
uci set ruantiblock.list1.u_t_proxy_type='1'
uci set ruantiblock.list2.u_proxy_mode='3'
uci set ruantiblock.list2.u_t_proxy_type='1'
uci set ruantiblock.list3.u_proxy_mode='3'
uci set ruantiblock.list3.u_t_proxy_type='1'
uci set ruantiblock.list4.u_proxy_mode='3'
uci set ruantiblock.list4.u_t_proxy_type='1'
uci set ruantiblock.list5.u_proxy_mode='3'
uci set ruantiblock.list5.u_t_proxy_type='1'
uci commit ruantiblock


echo "Launching services"
service sing-box enable
service sing-box restart
service ruantiblock enable
service ruantiblock restart
ruantiblock update
