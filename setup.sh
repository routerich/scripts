#!/bin/sh
wget --no-check-certificate -O /tmp/autoinstall.sh https://raw.githubusercontent.com/gSpotx2f/ruantiblock_openwrt/master/autoinstall/current/autoinstall.sh && chmod +x /tmp/autoinstall.sh && printf '%s\n' 2 2 Y Y | /tmp/autoinstall.sh
opkg update
opkg install kmod-tun unzip
service vpn disable
service vpn stop
cat <<'EOF' > /etc/init.d/tun2socks
#!/bin/sh /etc/rc.common
# Copyright (C) 2011 OpenWrt.org

USE_PROCD=1
START=40
STOP=89
PROG=/usr/bin/tun2socks
IF="tun0"
PROTO="http"
HOST="127.0.0.1"
PORT="18080"
start_service() {
        procd_open_instance
        procd_set_param command "$PROG" -device "$IF" -proxy "$PROTO"://"$HOST":"$PORT" -loglevel silent
        procd_set_param stdout 1
        procd_set_param stderr 1
        procd_set_param respawn ${respawn_threshold:-3600} ${respawn_timeout:-5} ${respawn_retry:-5}
        procd_close_instance
}
EOF
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

chmod +x /etc/init.d/tun2socks
chmod +x /etc/init.d/vpn

url="https://github.com/Snawoot/opera-proxy/releases/download/v1.4.2/opera-proxy.linux-arm64"
destination_file="/usr/bin/vpns"

echo "Uploading a file..."
wget "$url" -O "$destination_file" || { echo "Failed to download the file"; exit 1; }
echo "Adding execution permission..."
chmod +x "$destination_file" || { echo "Failed to add execution permission"; exit 1; }
echo "The file was successfully downloaded and moved to $destination_file"


url="https://github.com/xjasonlyu/tun2socks/releases/download/v2.5.2/tun2socks-linux-arm64.zip"
temp_dir="/tmp/tun2socks"
mkdir -p "$temp_dir"
echo "Downloading a ZIP archive..."
wget "$url" -O "$temp_dir/tun2socks-linux-arm64.zip" || { echo "The ZIP archive could not be downloaded"; exit 1; }
echo "Unpacking the ZIP archive..."
unzip -q "$temp_dir/tun2socks-linux-arm64.zip" -d "$temp_dir" || { echo "The ZIP archive could not be unzipped"; exit 1; }
echo "Renaming the executable file..."
mv "$temp_dir/tun2socks-linux-arm64" "$temp_dir/tun2socks" || { echo "Failed to rename the executable file"; exit 1; }
echo "Adding execution permission..."
chmod +x "$temp_dir/tun2socks" || { echo "Failed to add execution permission"; exit 1; }
echo "Moving the file to /usr/bin/..."
mv "$temp_dir/tun2socks" "/usr/bin/" || { echo "Failed to move file to /usr/bin/"; exit 1; }
echo "The file was successfully downloaded, unpacked, renamed and moved to /usr/bin/"

echo "Installing the TUN0 interface"
uci set network.tun0=interface
uci set network.tun0.proto='static'
uci set network.tun0.device='tun0'
uci set network.tun0.ipaddr='172.16.250.1'
uci set network.tun0.netmask='255.255.255.0'
uci commit network

echo "Installing a Firewall"
uci add_list firewall.cfg03dc81.network='tun0'
uci commit firewall

echo "Configuring Ruantiblock"
uci set ruantiblock.config.proxy_mode='2'
uci set ruantiblock.config.bllist_preset='ruantiblock-fqdn'
uci set ruantiblock.config.add_user_entries='1'
uci commit ruantiblock
/usr/bin/ruantiblock update
/etc/init.d/ruantiblock enable
/etc/init.d/cron enable
echo "0 3 */3 * * /usr/bin/ruantiblock update" >> /etc/crontabs/root
/etc/init.d/cron restart

echo "Launching services"
/etc/init.d/tun2socks enable
/etc/init.d/vpn enable
/etc/init.d/tun2socks start
/etc/init.d/vpn start

echo "Saving settings"
/etc/init.d/firewall restart
/etc/init.d/network restart
