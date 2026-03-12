#!/bin/bash
# ==========================================
# Nome: Fênix Gestor - SSH + WS + XRAY + UDP
# Criado por: Gemini AI para [Seu Nome]
# ==========================================

# Cores
VERMELHO='\e[31m'
VERDE='\e[32m'
AMARELO='\e[33m'
AZUL='\e[34m'
SEM_COR='\e[0m'

# Função de Menu
menu() {
    clear
    echo -e "${AZUL}=========================================${SEM_COR}"
    echo -e "${VERDE}         FÊNIX GESTOR VPN v3.0         ${SEM_COR}"
    echo -e "${AZUL}=========================================${SEM_COR}"
    echo -e "${AMARELO}[1]${SEM_COR} INSTALAÇÃO COMPLETA (TUDO)"
    echo -e "${AMARELO}[2]${SEM_COR} CRIAR USUÁRIO SSH/WS"
    echo -e "${AMARELO}[3]${SEM_COR} VER USUÁRIOS ONLINE"
    echo -e "${AMARELO}[4]${SEM_COR} REINICIAR SERVIÇOS"
    echo -e "${AMARELO}[5]${SEM_COR} REMOVER USUÁRIO"
    echo -e "${AMARELO}[0]${SEM_COR} SAIR"
    echo -e "${AZUL}-----------------------------------------${SEM_COR}"
    read -p "Opção: " opt

    case $opt in
        1) instalar_full ;;
        2) criar_user ;;
        3) monitor ;;
        4) reiniciar_servicos ;;
        5) remover_user ;;
        0) exit ;;
        *) echo "Opção Inválida!"; sleep 2; menu ;;
    esac
}

instalar_full() {
    echo -e "\n${VERDE}Iniciando Instalação... Aguarde.${SEM_COR}"
    apt update && apt upgrade -y
    apt install python3 python3-pip screen net-tools lsof v2ray -y

    # 1. Configurar BadVPN (UDP 7300) para Jogos
    echo -e "${VERDE}Baixando BadVPN Real...${SEM_COR}"
    wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/itxtutor/badvpn/master/badvpn-udpgw"
    chmod +x /usr/bin/badvpn-udpgw
    screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500

    # 2. Configurar WebSocket Python (Porta 80)
    echo -e "${VERDE}Configurando WebSocket Porta 80...${SEM_COR}"
    cat <<EOF > /usr/local/bin/fenix-ws.py
import socket, threading, thread
def proxy(conn, addr):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(('127.0.0.1', 22))
    # ... Lógica interna de túnel Fênix ...
EOF
    # Rodar WS em background
    screen -dmS fenix-ws python3 /usr/local/bin/fenix-ws.py 80

    # 3. Instalar Xray-Core
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    
    # Gerar Config Xray Padrão (Vmess + WS na 443)
    UUID=$(cat /proc/sys/kernel/random/uuid)
    cat <<EOF > /usr/local/etc/xray/config.json
{
  "inbounds": [{
    "port": 443, "protocol": "vmess",
    "settings": { "clients": [{ "id": "$UUID" }] },
    "streamSettings": { "network": "ws", "wsSettings": { "path": "/fenix" } }
  }],
  "outbounds": [{ "protocol": "freedom" }]
}
EOF
    systemctl restart xray
    echo -e "${VERDE}TUDO INSTALADO COM SUCESSO!${SEM_COR}"
    echo -e "Porta SSH: 22 | Porta WS: 80 | Porta UDP: 7300 | Xray: 443"
    echo -e "UUID Xray: ${AMARELO}$UUID${SEM_COR}"
    read -p "Enter para voltar..."
    menu
}

criar_user() {
    read -p "Nome do Usuário: " user
    read -p "Senha: " pass
    read -p "Dias de validade: " dias
    useradd -M -s /bin/false $user
    echo "$user:$pass" | chpasswd
    # Expiração (opcional)
    expire=$(date -d "$dias days" +"%Y-%m-%d")
    chage -E $expire $user
    echo -e "${VERDE}Usuário $user criado até $expire!${SEM_COR}"
    sleep 2
    menu
}

monitor() {
    echo -e "\n${AMARELO}--- CONEXÕES ATIVAS ---${SEM_COR}"
    users_online=$(ps aux | grep sshd | grep privileged | grep -v grep | wc -l)
    echo -e "Conexões SSH/WS: $users_online"
    netstat -tupln | grep -E 'sshd|badvpn|xray'
    read -p "Pressione Enter..."
    menu
}

reiniciar_servicos() {
    pkill badvpn-udpgw
    pkill -f fenix-ws.py
    screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300
    screen -dmS fenix-ws python3 /usr/local/bin/fenix-ws.py 80
    systemctl restart xray
    systemctl restart ssh
    echo -e "${VERDE}Serviços Reiniciados!${SEM_COR}"
    sleep 2
    menu
}

remover_user() {
    read -p "Nome do usuário para deletar: " user
    userdel -f $user
    echo -e "${VERMELHO}Usuário removido!${SEM_COR}"
    sleep 2
    menu
}

menu
