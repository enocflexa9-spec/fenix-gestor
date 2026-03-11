#!/bin/bash

SCRIPT="🦅 FÊNIX GESTOR ULTRA PRO"
XRAY_CONFIG="/usr/local/etc/xray/config.json"
UPDATE_URL="https://seu-servidor.com/fenix.sh"
SCRIPT_PATH="/usr/local/bin/fenix"

# ===============================
# VERIFICAR ROOT
# ===============================

if [[ $EUID -ne 0 ]]; then
 echo "Execute como ROOT!"
 exit
fi

# ===============================
# CORES
# ===============================

GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
RESET="\033[0m"

# ===============================
# BANNER
# ===============================

banner(){
clear
echo -e "${GREEN}"
echo "========================================"
echo "        $SCRIPT"
echo "   GERENCIADOR DE SERVIDOR"
echo "========================================"
echo -e "${RESET}"
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

apt install curl wget jq net-tools bc unzip htop git cmake make gcc build-essential nginx dante-server ufw -y

echo "Sistema preparado!"

pause
}

# ===============================
# INSTALAR XRAY
# ===============================

install_xray(){

banner

bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh)

systemctl enable xray
systemctl restart xray

echo "XRAY instalado!"

pause
}

# ===============================
# GERENCIAR SSH
# ===============================

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

read -p "Usuário para remover: " user
userdel $user

echo "Usuário removido!"

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

# ===============================
# PORTAS SSH
# ===============================

port_manager(){

while true
do

banner

echo "1 - Ver portas SSH"
echo "2 - Adicionar porta"
echo "3 - Alterar porta principal"
echo "0 - Voltar"

read -p "Escolha: " op

case $op in

1)
grep "^Port" /etc/ssh/sshd_config
pause
;;

2)
read -p "Nova porta: " porta
echo "Port $porta" >> /etc/ssh/sshd_config
systemctl restart ssh
pause
;;

3)
read -p "Nova porta principal: " porta
sed -i "s/^Port.*/Port $porta/" /etc/ssh/sshd_config
systemctl restart ssh
pause
;;

0)
break
;;

esac

done
}

# ===============================
# XRAY MANAGER
# ===============================

xray_manager(){

while true
do

banner

echo "1 - Reiniciar XRAY"
echo "2 - Status XRAY"
echo "3 - Ver config XRAY"
echo "0 - Voltar"

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

# ===============================
# BADVPN
# ===============================

install_badvpn(){

banner

cd /root
git clone https://github.com/ambrop72/badvpn.git

cd badvpn
mkdir build
cd build

cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1
make install

cat <<EOF >/etc/systemd/system/badvpn.service
[Unit]
Description=BadVPN UDPGW
After=network.target

[Service]
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable badvpn
systemctl restart badvpn

pause
}

badvpn_manager(){

while true
do

banner

echo "1 - Instalar BadVPN"
echo "2 - Reiniciar BadVPN"
echo "3 - Status BadVPN"
echo "0 - Voltar"

read -p "Escolha: " op

case $op in

1) install_badvpn ;;
2) systemctl restart badvpn ;;
3) systemctl status badvpn ;;
0) break ;;

esac

pause

done
}

# ===============================
# WEBSOCKET
# ===============================

ws_port_manager(){

while true
do

banner

echo "1 - Ver portas WebSocket"
echo "2 - Adicionar porta WebSocket"
echo "3 - Remover porta WebSocket"
echo "0 - Voltar"

read -p "Escolha: " op

case $op in

1)
grep listen /etc/nginx/conf.d/*
pause
;;

2)

read -p "Porta WS: " porta

cat <<EOF >/etc/nginx/conf.d/ws-$porta.conf
server {
 listen $porta;

 location /sshws {
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
;;

3)

read -p "Porta remover: " porta

rm -f /etc/nginx/conf.d/ws-$porta.conf
systemctl restart nginx

pause
;;

0)
break
;;

esac

done
}

# ===============================
# SOCKS
# ===============================

socks_port_manager(){

while true
do

banner

echo "1 - Ver porta SOCKS"
echo "2 - Alterar porta SOCKS"
echo "3 - Reiniciar SOCKS"
echo "0 - Voltar"

read -p "Escolha: " op

case $op in

1)
grep "port =" /etc/danted.conf
pause
;;

2)

read -p "Nova porta: " porta

sed -i "s/port = .*/port = $porta/" /etc/danted.conf

systemctl restart danted

pause
;;

3)

systemctl restart danted

pause
;;

0)
break
;;

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

echo "1 - Ativar firewall automático"
echo "2 - Status firewall"
echo "3 - Abrir porta"
echo "4 - Bloquear porta"
echo "0 - Voltar"

read -p "Escolha: " op

case $op in

1)

ufw default deny incoming
ufw default allow outgoing

ufw allow 22
ufw allow 80
ufw allow 443
ufw allow 7300

ufw enable

pause
;;

2)

ufw status
pause
;;

3)

read -p "Porta liberar: " porta
ufw allow $porta
pause
;;

4)

read -p "Porta bloquear: " porta
ufw delete allow $porta
pause
;;

0)
break
;;

esac

done
}

# ===============================
# AUTO UPDATE
# ===============================

auto_update(){

banner

echo "Atualizando script..."

curl -s $UPDATE_URL -o /tmp/fenix_update.sh

if [ -s /tmp/fenix_update.sh ]; then

chmod +x /tmp/fenix_update.sh
mv /tmp/fenix_update.sh $SCRIPT_PATH

echo "Script atualizada!"

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
echo "Uptime:"
uptime

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

# ===============================
# MENU SSH
# ===============================

ssh_menu(){

while true
do

banner

echo "1 - Criar usuário SSH"
echo "2 - Remover usuário"
echo "3 - Listar usuários"
echo "4 - Usuários online"
echo "0 - Voltar"

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

# ===============================
# MENU PRINCIPAL
# ===============================

menu(){

while true
do

banner

echo "1 - Preparar sistema"
echo "2 - Instalar XRAY"
echo "3 - Gerenciar SSH"
echo "4 - Gerenciar portas SSH"
echo "5 - Gerenciar XRAY"
echo "6 - Informações do servidor"
echo "7 - Gerenciar BadVPN"
echo "8 - Gerenciar WebSocket"
echo "9 - Gerenciar SOCKS"
echo "10 - Firewall"
echo "11 - Atualizar Fênix Gestor"
echo "0 - Sair"

read -p "Escolha: " opcao

case $opcao in

1) install_system ;;
2) install_xray ;;
3) ssh_menu ;;
4) port_manager ;;
5) xray_manager ;;
6) server_info ;;
7) badvpn_manager ;;
8) ws_port_manager ;;
9) socks_port_manager ;;
10) firewall_manager ;;
11) auto_update ;;
0) exit ;;

esac

done
}

menu