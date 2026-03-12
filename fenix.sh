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
echo "====================================="
echo "        $SCRIPT"
echo "====================================="
echo -e "${RESET}"
}

pause(){
read -p "Pressione ENTER..."
}

iface=$(ip route | grep default | awk '{print $5}')

# ==============================
# PREPARAR SISTEMA
# ==============================

install_system(){

banner

apt update -y

apt install -y \
curl wget jq net-tools git unzip \
build-essential cmake make gcc \
socat nginx dante-server badvpn \
ufw uuid-runtime

pause
}

# ==============================
# XRAY
# ==============================

install_xray(){

banner

bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh)

systemctl enable xray
systemctl restart xray

pause
}

# ==============================
# SSH
# ==============================

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

remove_ssh(){

banner
read -p "Usuário: " user
userdel $user
pause
}

list_ssh(){

banner
awk -F: '$3 >= 1000 {print $1}' /etc/passwd
pause
}

ssh_menu(){

while true
do

banner

echo "1 Criar usuário"
echo "2 Remover usuário"
echo "3 Listar usuários"
echo "0 Voltar"

read -p "Escolha: " op

case $op in

1) create_ssh ;;
2) remove_ssh ;;
3) list_ssh ;;
0) break ;;

esac

done
}

# ==============================
# WEBSOCKET REAL
# ==============================

install_websocket(){

banner

apt install -y socat wget

cd /usr/local/bin

wget -O websocketd \
https://github.com/joewalnes/websocketd/releases/download/v0.4.1/websocketd-linux_amd64

chmod +x websocketd

cat <<EOF >/usr/local/bin/ws-ssh
#!/bin/bash
/usr/bin/socat STDIO TCP4:127.0.0.1:22
EOF

chmod +x /usr/local/bin/ws-ssh

cat <<EOF >/etc/systemd/system/ws.service
[Unit]
Description=WebSocket SSH
After=network.target

[Service]
ExecStart=/usr/local/bin/websocketd --port=80 /usr/local/bin/ws-ssh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ws
systemctl restart ws

echo "WebSocket ativo na porta 80"

pause
}

add_ws_port(){

banner

read -p "Porta WebSocket: " porta

cat <<EOF >/etc/systemd/system/ws-$porta.service
[Unit]
Description=WebSocket SSH $porta
After=network.target

[Service]
ExecStart=/usr/local/bin/websocketd --port=$porta /usr/local/bin/ws-ssh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ws-$porta
systemctl restart ws-$porta

pause
}

list_ws_ports(){

banner
systemctl list-units | grep ws
pause
}

# ==============================
# SOCKS
# ==============================

install_socks(){

banner

apt install -y dante-server

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

echo "SOCKS5 rodando na porta 8080"

pause
}

add_socks_port(){

banner

read -p "Nova porta SOCKS: " porta

echo "internal: 0.0.0.0 port = $porta" >> /etc/danted.conf

systemctl restart danted

pause
}

list_socks_ports(){

banner
grep internal /etc/danted.conf
pause
}

# ==============================
# BADVPN
# ==============================

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

echo "BadVPN ativo na porta 7300"

pause
}

add_badvpn_port(){

banner

read -p "Nova porta BadVPN: " porta

cat <<EOF >/etc/systemd/system/badvpn-$porta.service
[Unit]
Description=BadVPN $porta
After=network.target

[Service]
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 0.0.0.0:$porta
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable badvpn-$porta
systemctl restart badvpn-$porta

pause
}

# ==============================
# FIREWALL
# ==============================

firewall_manager(){

banner

ufw allow 22
ufw allow 80
ufw allow 8080
ufw allow 7300

ufw enable

pause
}

# ==============================
# UUID XRAY
# ==============================

generate_uuid(){

banner
uuidgen
pause
}

# ==============================
# MENU
# ==============================

menu(){

while true
do

banner

echo "1 Preparar sistema"
echo "2 Instalar XRAY"
echo "3 Gerenciar SSH"
echo "4 Instalar WebSocket"
echo "5 Adicionar porta WebSocket"
echo "6 Instalar SOCKS"
echo "7 Adicionar porta SOCKS"
echo "8 Instalar BadVPN"
echo "9 Adicionar porta BadVPN"
echo "10 Firewall"
echo "11 Gerar UUID XRAY"
echo "0 Sair"

read -p "Escolha: " op

case $op in

1) install_system ;;
2) install_xray ;;
3) ssh_menu ;;
4) install_websocket ;;
5) add_ws_port ;;
6) install_socks ;;
7) add_socks_port ;;
8) install_badvpn ;;
9) add_badvpn_port ;;
10) firewall_manager ;;
11) generate_uuid ;;
0) exit ;;

esac

done
}

menu