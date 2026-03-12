#!/bin/bash

SCRIPT="🦅 FÊNIX GESTOR ULTRA PRO"
INSTALL_PATH="/usr/local/bin/fenix"
XRAY_CONFIG="/usr/local/etc/xray/config.json"

GREEN="\033[1;32m"
RESET="\033[0m"

# =========================
# INSTALADOR AUTOMÁTICO
# =========================

if [[ $EUID -ne 0 ]]; then
 echo "Execute como ROOT!"
 exit
fi

if [[ "$0" != "$INSTALL_PATH" ]]; then

echo "Instalando Fênix Gestor..."

cp "$0" $INSTALL_PATH
chmod +x $INSTALL_PATH

echo ""
echo "Instalação concluída!"
echo "Execute com: fenix"
echo ""

exit
fi

# =========================
# BANNER
# =========================

banner(){
clear
echo -e "$GREEN"
echo "==================================="
echo "      $SCRIPT"
echo "==================================="
echo -e "$RESET"
}

pause(){
read -p "Pressione ENTER..."
}

# =========================
# INTERFACE REDE
# =========================

iface=$(ip route | grep default | awk '{print $5}')

# =========================
# PREPARAR SISTEMA
# =========================

install_system(){

banner

apt update -y
apt upgrade -y

apt install -y \
curl wget jq net-tools unzip git \
build-essential cmake make gcc \
nginx socat dante-server ufw uuid-runtime

echo "Sistema preparado!"

pause
}

# =========================
# XRAY
# =========================

install_xray(){

banner

bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh)

systemctl enable xray
systemctl restart xray

echo "XRAY instalado!"

pause
}

xray_manager(){

while true
do

banner

echo "1 Reiniciar XRAY"
echo "2 Status XRAY"
echo "3 Ver config"
echo "0 Voltar"

read -p "Escolha: " op

case $op in

1) systemctl restart xray ;;
2) systemctl status xray ;;
3) cat $XRAY_CONFIG ;;
0) break ;;

esac

pause

done
}

# =========================
# UUID
# =========================

generate_uuid(){

banner
uuidgen
pause
}

# =========================
# SSH
# =========================

create_ssh(){

banner

read -p "Usuário: " user
read -p "Senha: " pass
read -p "Dias validade: " dias

exp=$(date -d "$dias days" +"%Y-%m-%d")

useradd -e $exp -M -s /bin/false $user
echo "$user:$pass" | chpasswd

echo "Usuário criado!"

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

online_users(){

banner

who

pause
}

ssh_menu(){

while true
do

banner

echo "===== SSH MANAGER ====="

echo "1 Criar usuário"
echo "2 Remover usuário"
echo "3 Listar usuários"
echo "4 Usuários online"
echo "0 Voltar"

read -p "Escolha: " op

case $op in

1) create_ssh ;;
2) remove_ssh ;;
3) list_ssh ;;
4) online_users ;;
0) break ;;

esac

done
}

# =========================
# PORTAS SSH
# =========================

port_manager(){

while true
do

banner

echo "1 Ver portas"
echo "2 Adicionar porta"
echo "3 Alterar porta principal"
echo "0 Voltar"

read -p "Escolha: " op

case $op in

1) grep "^Port" /etc/ssh/sshd_config ;;

2)

read -p "Nova porta: " porta
echo "Port $porta" >> /etc/ssh/sshd_config
systemctl restart ssh

;;

3)

read -p "Nova porta principal: " porta
sed -i "s/^Port.*/Port $porta/" /etc/ssh/sshd_config
systemctl restart ssh

;;

0) break ;;

esac

pause

done
}

# =========================
# BADVPN
# =========================

install_badvpn(){

banner

apt install badvpn -y

badvpn-udpgw --listen-addr 0.0.0.0:7300 &

echo "BadVPN ativo na porta 7300"

pause
}

# =========================
# WEBSOCKET SSH REAL
# =========================

install_websocket(){

banner

wget -O /usr/local/bin/websocketd \
https://github.com/joewalnes/websocketd/releases/download/v0.4.1/websocketd-linux_amd64

chmod +x /usr/local/bin/websocketd

cat <<EOF >/usr/local/bin/ws-ssh
#!/bin/bash
socat STDIO TCP4:127.0.0.1:22
EOF

chmod +x /usr/local/bin/ws-ssh

cat <<EOF >/etc/systemd/system/ws.service
[Unit]
Description=WebSocket SSH
After=network.target

[Service]
ExecStart=/usr/local/bin/websocketd --port=8080 /usr/local/bin/ws-ssh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ws
systemctl restart ws

echo "WebSocket ativo na porta 8080"

pause
}

# =========================
# SOCKS5
# =========================

install_socks(){

banner

cat <<EOF >/etc/danted.conf
logoutput: syslog

internal: 0.0.0.0 port = 1080
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

echo "SOCKS5 ativo na porta 1080"

pause
}

# =========================
# FIREWALL
# =========================

firewall_manager(){

banner

ufw allow 22
ufw allow 80
ufw allow 443
ufw allow 8080
ufw allow 7300
ufw allow 1080

ufw enable

pause
}

# =========================
# INFO SERVIDOR
# =========================

server_info(){

banner

echo "IP:"
curl -s ifconfig.me

echo ""
echo "Memória:"
free -h

echo ""
echo "Disco:"
df -h

echo ""
echo "Portas:"
ss -tulpn

pause
}

# =========================
# MENU
# =========================

menu(){

while true
do

banner

echo "1 Preparar sistema"
echo "2 Instalar XRAY"
echo "3 Gerenciar SSH"
echo "4 Portas SSH"
echo "5 XRAY Manager"
echo "6 Info servidor"
echo "7 Instalar BadVPN"
echo "8 Instalar WebSocket"
echo "9 Instalar SOCKS"
echo "10 Firewall"
echo "11 Gerar UUID XRAY"
echo "0 Sair"

echo ""

read -p "Escolha: " op

case $op in

1) install_system ;;
2) install_xray ;;
3) ssh_menu ;;
4) port_manager ;;
5) xray_manager ;;
6) server_info ;;
7) install_badvpn ;;
8) install_websocket ;;
9) install_socks ;;
10) firewall_manager ;;
11) generate_uuid ;;
0) exit ;;

*) echo "Opção inválida"; sleep 1 ;;

esac

done
}

menu