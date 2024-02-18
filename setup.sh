#!/bin/sh

opkg update
opkg install kmod-tun unzip
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

url="https://github.com/Snawoot/opera-proxy/releases/download/v1.2.5/opera-proxy.linux-arm64"
destination_file="/usr/bin/vpns"

echo "Загрузка файла..."
wget "$url" -O "$destination_file" || { echo "Не удалось скачать файл"; exit 1; }
echo "Добавление разрешения на выполнение..."
chmod +x "$destination_file" || { echo "Не удалось добавить разрешение на выполнение"; exit 1; }
echo "Файл успешно скачан и перемещен в $destination_file"


url="https://github.com/xjasonlyu/tun2socks/releases/download/v2.5.2/tun2socks-linux-arm64.zip"
temp_dir="/tmp/tun2socks"
mkdir -p "$temp_dir"
echo "Загрузка ZIP-архива..."
wget "$url" -O "$temp_dir/tun2socks-linux-arm64.zip" || { echo "Не удалось скачать ZIP-архив"; exit 1; }
echo "Распаковка ZIP-архива..."
unzip -q "$temp_dir/tun2socks-linux-arm64.zip" -d "$temp_dir" || { echo "Не удалось распаковать ZIP-архив"; exit 1; }
echo "Переименование исполняемого файла..."
mv "$temp_dir/tun2socks-linux-arm64" "$temp_dir/tun2socks" || { echo "Не удалось переименовать исполняемый файл"; exit 1; }
echo "Добавление разрешения на выполнение..."
chmod +x "$temp_dir/tun2socks" || { echo "Не удалось добавить разрешение на выполнение"; exit 1; }
echo "Перемещение файла в /usr/bin/..."
mv "$temp_dir/tun2socks" "/usr/bin/" || { echo "Не удалось переместить файл в /usr/bin/"; exit 1; }
echo "Файл успешно скачан, распакован, переименован и перемещен в /usr/bin/"

echo "Устоновка интерфейса TUN0"
uci set network.tun0=interface
uci set network.tun0.proto='static'
uci set network.tun0.device='tun0'
uci set network.tun0.ipaddr='172.16.250.1'
uci set network.tun0.netmask='255.255.255.0'

echo "Устоновка Фаервола"
uci add_list firewall.cfg03dc81.network='tun0'

echo "Настройка Ruantiblock"
uci set ruantiblock.config.proxy_mode='2'
uci set ruantiblock.config.bllist_preset='ruantiblock-fqdn'
uci set ruantiblock.config.add_user_entries='1'
uci commit ruantiblock
/usr/bin/ruantiblock update
/etc/init.d/ruantiblock enable
/etc/init.d/cron enable
echo "0 3 */3 * * /usr/bin/ruantiblock update" >> /etc/crontabs/root
/etc/init.d/cron restart

echo "Запуск сервисов"
/etc/init.d/tun2socks enable
/etc/init.d/vpn enable
/etc/init.d/tun2socks restart
/etc/init.d/vpn restart

echo "Сохранение настроек"
uci commit firewall
uci commit network
/etc/init.d/firewall restart
/etc/init.d/network restart