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
read -p "Pressione ENTER..."
}

# ==================================
# PREPARAR SISTEMA
# ==================================

install_system(){

banner

apt update -y
apt upgrade -y

apt install -y \
curl wget jq net-tools unzip git \
cmake make gcc build-essential \
nginx dante-server ufw uuid-runtime \
socat

pause
}

# ==================================
# XRAY
# ==================================

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

# ==================================
# UUID
# ==================================

generate_uuid(){

banner
uuidgen
pause
}

# ==================================
# SSH
# ==================================

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

# ==================================
# PORTAS SSH
# ==================================

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
read -p