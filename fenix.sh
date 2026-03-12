#!/bin/bash

SCRIPT="🦅 FÊNIX GESTOR ULTRA PRO"

GREEN="\033[1;32m"
RESET="\033[0m"

if [[ $EUID -ne 0 ]]; then
 echo "Execute como ROOT!"
 exit
fi

banner(){
clear
echo -e "${GREEN}"
echo "================================="
echo "      $SCRIPT"
echo "================================="
echo -e "${RESET}"
}

pause(){
read -p "Pressione ENTER..."
}

iface=$(ip route | grep default | awk '{print $5}')

# ==========================
# PREPARAR SERVIDOR
# ==========================

prepare_server(){

banner

apt update -y

apt install -y \
curl wget git unzip \
net-tools socat \
dante-server badvpn \
ufw uuid-runtime

pause
}

# ==========================
# WEBSOCKET SSH
# ==========================

install_websocket(){

banner

cd /usr/local/bin

wget -O websocketd \
https://github.com/joewalnes/websocketd/releases/download/v0.4.1/websocketd-linux_amd64

chmod +x websocketd

cat <<EOF >/usr/local/bin/ws-ssh
#!/bin/bash
exec socat STDIO TCP4:127.0.0.1:22
EOF

chmod +x /usr/local/bin/ws-ssh

cat <<EOF >/etc/systemd/system/websocket.service
[Unit]
Description=WebSocket SSH Tunnel
After=network.target

[Service]
ExecStart=/usr/local/bin/websocketd --port=80 /usr/local/bin/ws-ssh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable websocket
systemctl restart websocket

pause
}

# ==========================
# SOCKS5
# ==========================

install_socks(){

banner

cat <<EOF >/etc/danted.conf
logoutput: syslog

internal: 0.0.0.0 port = 8080
external: $iface

method: username

user.notprivileged: nobody

client pass {
from: 0.0.0.0/0 to: 0.0.0.0/0
}

pass {
from: 0.0.0.0/0 to: 0.0.0.0/0
protocol: tcp udp
}
EOF

systemctl restart danted
systemctl enable danted

pause
}

# ==========================
# BADVPN
# ==========================

install_badvpn(){

banner

cat <<EOF >/etc/systemd/system/badvpn.service
[Unit]
Description=BadVPN UDPGW
After=network.target

[Service]
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 0.0.0.0:7300
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable badvpn
systemctl restart badvpn

pause
}

# ==========================
# FIREWALL
# ==========================

setup_firewall(){

banner

ufw allow 22
ufw allow 80
ufw allow 8080
ufw allow 7300

ufw --force enable

pause
}

# ==========================
# SSH USER
# ==========================

create_ssh(){

banner

read -p "Usuário: " user
read -p "Senha: " pass
read -p "Dias: " dias

exp=$(date -d "$dias days" +"%Y-%m-%d")

useradd -e $exp -M -s /bin/false $user
echo "$user:$pass" | chpasswd

pause
}

# ==========================
# UUID XRAY
# ==========================

uuid_xray(){

banner
uuidgen
pause
}

# ==========================
# MENU
# ==========================

menu(){

while true
do

banner

echo "1 Preparar servidor"
echo "2 Instalar WebSocket SSH"
echo "3 Instalar SOCKS5"
echo "4 Instalar BadVPN"
echo "5 Configurar Firewall"
echo "6 Criar usuário SSH"
echo "7 Gerar UUID XRAY"
echo "0 Sair"

read op

case $op in

1) prepare_server ;;
2) install_websocket ;;
3) install_socks ;;
4) install_badvpn ;;
5) setup_firewall ;;
6) create_ssh ;;
7) uuid_xray ;;
0) exit ;;

esac

done
}

menu