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
echo "======================================"
echo "       $SCRIPT"
echo "======================================"
echo -e "${RESET}"
}

pause(){
read -p "Pressione ENTER para continuar..."
}

iface=$(ip route | grep default | awk '{print $5}')

# =================================
# PREPARAR SISTEMA
# =================================

install_system(){

banner

apt update -y

apt install -y \
curl wget git unzip \
net-tools socat \
dante-server badvpn \
ufw uuid-runtime

pause
}

# =================================
# INSTALAR XRAY
# =================================

install_xray(){

banner

bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh)

systemctl enable xray
systemctl restart xray

pause
}

# =================================
# SSH MANAGER
# =================================

create_ssh(){

banner

read -p "Usuário: " user
read -p "Senha: " pass
read -p "Dias validade: " dias

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

echo "1 Criar usuário SSH"
echo "2 Remover usuário SSH"
echo "3 Listar usuários SSH"
echo "0 Voltar"

read op

case $op in

1) create_ssh ;;
2) remove_ssh ;;
3) list_ssh ;;
0) break ;;

esac

done
}

# =================================
# WEBSOCKET SSH
# =================================

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

cat <<EOF >/etc/systemd/system/websocket.service
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
systemctl enable websocket
systemctl restart websocket

pause
}

# =================================
# SOCKS5
# =================================

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

# =================================
# BADVPN
# =================================

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

# =================================
# FIREWALL
# =================================

firewall_setup(){

banner

ufw allow 22
ufw allow 80
ufw allow 8080
ufw allow 7300

ufw --force enable

pause
}

# =================================
# UUID XRAY
# =================================

generate_uuid(){

banner
uuidgen
pause
}

# =================================
# MENU PRINCIPAL
# =================================

menu(){

while true
do

banner

echo "1 Preparar sistema"
echo "2 Instalar XRAY"
echo "3 Gerenciar SSH"
echo "4 Instalar WebSocket SSH"
echo "5 Instalar SOCKS5"
echo "6 Instalar BadVPN"
echo "7 Configurar Firewall"
echo "8 Gerar UUID XRAY"
echo "0 Sair"

read op

case $op in

1) install_system ;;
2) install_xray ;;
3) ssh_menu ;;
4) install_websocket ;;
5) install_socks ;;
6) install_badvpn ;;
7) firewall_setup ;;
8) generate_uuid ;;
0) exit ;;

esac

done
}

menu