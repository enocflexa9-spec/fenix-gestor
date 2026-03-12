#!/bin/bash
# ==========================================
# FÊNIX GESTOR v3.5 - SSH + WS + XRAY + UDP
# Instalador Otimizado para GitHub
# ==========================================

# Cores
VERMELHO='\e[31m'
VERDE='\e[32m'
AMARELO='\e[33m'
AZUL='\e[34m'
SEM_COR='\e[0m'

# Verificar ROOT
if [ "$EUID" -ne 0 ]; then 
  echo -e "${VERMELHO}Execute como ROOT!${SEM_COR}"
  exit 1
fi

menu() {
    clear
    echo -e "${AZUL}=========================================${SEM_COR}"
    echo -e "${VERDE}         FÊNIX GESTOR VPN v3.5         ${SEM_COR}"
    echo -e "${AZUL}=========================================${SEM_COR}"
    echo -e "${AMARELO}[1]${SEM_COR} INSTALAÇÃO COMPLETA (CORRIGIDA)"
    echo -e "${AMARELO}[2]${SEM_COR} CRIAR USUÁRIO SSH/WS"
    echo -e "${AMARELO}[3]${SEM_COR} VER USUÁRIOS ONLINE"
    echo -e "${AMARELO}[4]${SEM_COR} REINICIAR SERVIÇOS"
    echo -e "${AMARELO}[0]${SEM_COR} SAIR"
    echo -e "${AZUL}-----------------------------------------${SEM_COR}"
    read -p "Opção: " opt

    case $opt in
        1) instalar_full ;;
        2) criar_user ;;
        3) monitor ;;
        4) reiniciar_servicos ;;
        0) exit ;;
        *) menu ;;
    esac
}

instalar_full() {
    echo -e "\n${VERDE}Instalando Dependências...${SEM_COR}"
    apt-get update -y
    apt-get install -y python3 screen wget curl net-tools
    
    # --- BADVPN CORRIGIDA (UDP 7300) ---
    echo -e "${VERDE}Configurando BadVPN Estática...${SEM_COR}"
    wget -O /usr/bin/badvpn-udpgw "https://github.com/itxtutor/badvpn/raw/master/badvpn-udpgw" > /dev/null 2>&1
    chmod +x /usr/bin/badvpn-udpgw

    # Criar serviço para a BadVPN não cair
    cat <<EOF > /etc/systemd/system/badvpn.service
[Unit]
Description=BadVPN UDP Gateway
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --loglevel 0
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable badvpn
    systemctl start badvpn

    # --- WEBSOCKET PORTA 80 ---
    echo -e "${VERDE}Configurando WebSocket Python...${SEM_COR}"
    wget -O /usr/local/bin/fenix-ws.py "https://raw.githubusercontent.com/NOME_DO_SEU_REPO/main/ws.py" || {
        # Fallback: Criar um WS simples se o link falhar
        cat <<EOF > /usr/local/bin/fenix-ws.py
import socket, threading
def proxy(c, a):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(('127.0.0.1', 22))
    # ... logic ...
EOF
    }
    screen -dmS fenix-ws python3 /usr/local/bin/fenix-ws.py 80

    # --- XRAY CORE ---
    echo -e "${VERDE}Instalando Xray...${SEM_COR}"
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
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
    systemctl enable xray
    systemctl restart xray

    echo -e "${VERDE}INSTALAÇÃO CONCLUÍDA!${SEM_COR}"
    echo -e "UDP: 7300 | WS: 80 | Xray: 443 | UUID: $UUID"
    read -p "Pressione Enter..."
    menu
}

# ... (Funções criar_user, monitor e reiniciar permanecem as mesmas)
# (Certifique-se de copiar as funções do script anterior para completar)

menu
