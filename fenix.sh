#!/bin/bash

SCRIPT="🦅 FÊNIX GESTOR ULTRA PRO"
XRAY_CONFIG="/usr/local/etc/xray/config.json"
UPDATE_URL="https://raw.githubusercontent.com/enocflexa9-spec/fenix-gestor/main/fenix.sh"
SCRIPT_PATH="/usr/local/bin/fenix"

if [[ $EUID -ne 0 ]]; then
 echo "Execute como ROOT!"
 exit
fi

GREEN="\033[1;32m"
RESET="\033[0m"

banner(){
clear
echo -e "$GREEN"
echo "======================================="
echo "        $SCRIPT"
echo "======================================="
echo -e "$RESET"
}

pause(){
read -p "Pressione ENTER para continuar..."
}

# ===============================
# PREPARAR SISTEMA
# ===============================

install_system(){

banner

apt update -y
apt upgrade -y

apt install -y curl wget jq net-tools unzip htop git cmake make gcc \
build-essential nginx dante-server ufw uuid-runtime

pause
}

# ===============================
# XRAY
# ===============================

install_xray(){

banner

bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh)

systemctl enable xray
systemctl restart xray

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

read op

case $op in
1) systemctl restart xray ;;
2) systemctl status xray ;;
3) cat $XRAY_CONFIG ;;
0) break ;;
esac

pause

done
}

# ===============================
# UUID XRAY
# ===============================

generate_uuid(){

banner

uuidgen

pause
}

# ===============================
# SSH
# ===============================

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

online_users(){

banner

who

pause
}

ssh_menu(){

while true
do

banner

echo "1 Criar usuário"
echo "2 Remover usuário"
echo "3 Listar usuários"
echo "4 Usuários online"
echo "0 Voltar"

read op

case $op in
1) create_ssh ;;
2) remove_ssh ;;
3) list_ssh ;;
4) online_users ;;
0) break ;;
esac

done
}

# ===============================
# PORTAS SSH
# ===============================

port_manager(){

while true
do

banner

echo "1 Ver portas"
echo "2 Adicionar porta"
echo "3 Alterar porta principal"
echo "0 Voltar"

read op

case $op in

1) grep "^Port" /etc/ssh/sshd_config ;;

2)
read -p "Nova porta: " porta
echo "Port $porta" >> /etc/ssh/sshd_config
systemctl restart ssh
;;

3)
read -p "Nova porta: " porta
sed -i "s/^Port.*/Port $porta/" /etc/ssh/sshd_config
systemctl restart ssh
;;

0) break ;;

esac

pause

done
}

# ===============================
# BADVPN
# ===============================

install_badvpn(){

banner

apt install git cmake make gcc -y

cd /root

if [ ! -d badvpn ]; then
git clone https://github.com/ambrop72/badvpn.git
fi

cd badvpn
mkdir -p build
cd build

cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1
make install

cat <<EOF >/etc/systemd/system/badvpn-7300.service
[Unit]
Description=BadVPN UDPGW 7300
After=network.target

[Service]
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 0.0.0.0:7300
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable badvpn-7300
systemctl start badvpn-7300

pause
}

add_badvpn_port(){

banner

read -p "Nova porta: " porta

cat <<EOF >/etc/systemd/system/badvpn-$porta.service
[Unit]
Description=BadVPN UDPGW $porta
After=network.target

[Service]
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 0.0.0.0:$porta
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable badvpn-$porta
systemctl start badvpn-$porta

pause
}

remove_badvpn_port(){

banner

read -p "Porta: " porta

systemctl stop badvpn-$porta
systemctl disable badvpn-$porta

rm /etc/systemd/system/badvpn-$porta.service

systemctl daemon-reload

pause
}

list_badvpn_ports(){

banner

ls /etc/systemd/system | grep badvpn

pause
}

badvpn_manager(){

while true
do

banner

echo "1 Instalar BadVPN"
echo "2 Ver portas"
echo "3 Adicionar porta"
echo "4 Remover porta"
echo "0 Voltar"

read op

case $op in

1) install_badvpn ;;
2) list_badvpn_ports ;;
3) add_badvpn_port ;;
4) remove_badvpn_port ;;
0) break ;;

esac

done
}

# ===============================
# WEBSOCKET SSH
# ===============================

install_websocket(){

banner

cat <<EOF >/etc/nginx/conf.d/websocket.conf
server {

listen 80;

location /ws {

proxy_pass http://127.0.0.1:22;

proxy_http_version 1.1;

proxy_set_header Upgrade \$http_upgrade;
proxy_set_header Connection "upgrade";
proxy_set_header Host \$host;

}

}
EOF

systemctl restart nginx

pause
}

add_ws_port(){

banner

read -p "Porta WS: " porta

cat <<EOF >/etc/nginx/conf.d/ws-$porta.conf
server {

listen $porta;

location /ws {

proxy_pass http://127.0.0.1:22;

proxy_http_version 1.1;

proxy_set_header Upgrade \$http_upgrade;
proxy_set_header Connection "upgrade";
proxy_set_header Host \$host;

}

}
EOF

systemctl restart nginx

pause
}

remove_ws_port(){

banner

read -p "Porta WS: " porta

rm /etc/nginx/conf.d/ws-$porta.conf

systemctl restart nginx

pause
}

list_ws_ports(){

banner

ls /etc/nginx/conf.d | grep ws

pause
}

websocket_manager(){

while true
do

banner

echo "1 Instalar WebSocket"
echo "2 Ver portas"
echo "3 Adicionar porta"
echo "4 Remover porta"
echo "0 Voltar"

read op

case $op in

1) install_websocket ;;
2) list_ws_ports ;;
3) add_ws_port ;;
4) remove_ws_port ;;
0) break ;;

esac

done
}

# ===============================
# SOCKS PROXY
# ===============================

install_socks(){

banner

cat <<EOF >/etc/danted.conf
logoutput: syslog

internal: 0.0.0.0 port = 1080
external: eth0

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

pause
}

add_socks_port(){

banner

read -p "Porta SOCKS: " porta

echo "internal: 0.0.0.0 port = $porta" >> /etc/danted.conf

systemctl restart danted

pause
}

remove_socks_port(){

banner

read -p "Porta: " porta

sed -i "/$porta/d" /etc/danted.conf

systemctl restart danted

pause
}

list_socks_ports(){

banner

grep internal /etc/danted.conf

pause
}

socks_manager(){

while true
do

banner

echo "1 Instalar SOCKS"
echo "2 Ver portas"
echo "3 Adicionar porta"
echo "4 Remover porta"
echo "0 Voltar"

read op

case $op in

1) install_socks ;;
2) list_socks_ports ;;
3) add_socks_port ;;
4) remove_socks_port ;;
0) break ;;

esac

done
}

# ===============================
# FIREWALL
# ===============================

firewall_manager(){

while true
do

banner

echo "1 Ativar firewall"
echo "2 Status"
echo "3 Abrir porta"
echo "4 Fechar porta"
echo "0 Voltar"

read op

case $op in

1)
ufw default deny incoming
ufw default allow outgoing

ufw allow 22
ufw allow 80
ufw allow 443
ufw allow 7300

ufw enable
;;

2) ufw status ;;

3)
read -p "Porta: " porta
ufw allow $porta
;;

4)
read -p "Porta: " porta
ufw delete allow $porta
;;

0) break ;;

esac

pause

done
}

# ===============================
# AUTO UPDATE
# ===============================

auto_update(){

banner

curl -s $UPDATE_URL -o /tmp/fenix_update.sh

if [ -s /tmp/fenix_update.sh ]; then

chmod +x /tmp/fenix_update.sh
mv /tmp/fenix_update.sh $SCRIPT_PATH

echo "Atualizado!"

else

echo "Falha na atualização"

fi

pause
}

# ===============================
# INFO SERVIDOR
# ===============================

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
echo "Portas abertas:"
ss -tulpn

pause
}

# ===============================
# MENU PRINCIPAL
# ===============================

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
echo "7 BadVPN Manager"
echo "8 WebSocket Manager"
echo "9 SOCKS Manager"
echo "10 Firewall"
echo "11 Atualizar script"
echo "12 Gerar UUID XRAY"
echo "0 Sair"

read op

case $op in

1) install_system ;;
2) install_xray ;;
3) ssh_menu ;;
4) port_manager ;;
5) xray_manager ;;
6) server_info ;;
7) badvpn_manager ;;
8) websocket_manager ;;
9) socks_manager ;;
10) firewall_manager ;;
11) auto_update ;;
12) generate_uuid ;;
0) exit ;;

esac

done
}

menu