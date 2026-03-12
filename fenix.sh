#!/bin/bash
# ==========================================
# FÊNIX GESTOR v10.0 - FULL INSTALLER
# ==========================================

VERDE='\033[1;32m'; VERMELHO='\033[1;31m'; AMARELO='\033[1;33m'; AZUL='\033[1;34m'; SEM_COR='\033[0m'

# --- FUNÇÃO INSTALAR TUDO (AUTO-INSTALL) ---
instalar_tudo() {
    clear
    echo -e "${AMARELO}Iniciando Instalação Completa...${SEM_COR}"
    apt update && apt install python3 screen wget curl net-tools -y > /dev/null 2>&1

    # 1. Instalar BadVPN (UDP 7300)
    echo -e "${AZUL}Instalando BadVPN (UDP)...${SEM_COR}"
    wget -O /usr/bin/badvpn-udpgw "https://github.com/itxtutor/badvpn/raw/master/badvpn-udpgw" > /dev/null 2>&1
    chmod +x /usr/bin/badvpn-udpgw
    screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000

    # 2. Instalar WebSocket (Porta 80)
    echo -e "${AZUL}Instalando WebSocket Python...${SEM_COR}"
    cat <<'EOF' > /usr/local/bin/fenix-ws.py
import socket, threading
def tunnel(source, destination):
    try:
        while True:
            data = source.recv(8192)
            if not data: break
            destination.sendall(data)
    except: pass
    finally: source.close(); destination.close()
def handle_client(client_sock):
    try:
        data = client_sock.recv(1024).decode('utf8', errors='ignore')
        if "Upgrade: websocket" in data:
            client_sock.send(b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n")
            ssh_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            ssh_sock.connect(('127.0.0.1', 22))
            threading.Thread(target=tunnel, args=(client_sock, ssh_sock)).start()
            tunnel(ssh_sock, client_sock)
    except: client_sock.close()
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(('0.0.0.0', 80))
server.listen(100)
while True:
    sock, addr = server.accept()
    threading.Thread(target=handle_client, args=(sock,)).start()
EOF
    pkill -f fenix-ws.py
    screen -dmS fenix-ws python3 /usr/local/bin/fenix-ws.py

    # 3. Instalar Xray (Porta 443)
    echo -e "${AZUL}Instalando Xray-Core...${SEM_COR}"
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install > /dev/null 2>&1
    uuid=$(cat /proc/sys/kernel/random/uuid)
    cat <<EOF > /usr/local/etc/xray/config.json
{
  "inbounds": [{
    "port": 443, "protocol": "vmess",
    "settings": { "clients": [{ "id": "$uuid" }] },
    "streamSettings": { "network": "ws", "wsSettings": { "path": "/fenix" } }
  }],
  "outbounds": [{ "protocol": "freedom" }]
}
EOF
    systemctl restart xray > /dev/null 2>&1

    echo -e "${VERDE}INSTALAÇÃO CONCLUÍDA!${SEM_COR}"
    echo -e "Portas: WS: 80 | Xray: 443 | UDP: 7300"
    echo -e "UUID Xray: $uuid"
    read -p "Pressione Enter para voltar ao menu..." ; menu_principal
}

# --- MENU PRINCIPAL ---
menu_principal() {
    clear
    echo -e "${VERDE}=========================================${SEM_COR}"
    echo -e "          FENIX GESTOR v10.0 PRO         "
    echo -e "${VERDE}=========================================${SEM_COR}"
    echo -e "${AMARELO}[1]${SEM_COR} INSTALAÇÃO COMPLETA (WS+XRAY+BAD)"
    echo -e "${AMARELO}[2]${SEM_COR} CRIAR USUÁRIO SSH"
    echo -e "${AMARELO}[3]${SEM_COR} VER CONFIGURAÇÕES / UUID"
    echo -e "${AMARELO}[4]${SEM_COR} MUDAR PORTAS"
    echo -e "${AMARELO}[0]${SEM_COR} SAIR"
    echo -e "${VERDE}=========================================${SEM_COR}"
    read -p "Escolha: " opt
    case $opt in
        1) instalar_tudo ;;
        2) 
            read -p "User: " u && read -p "Pass: " p && read -p "Dias: " d
            e=$(date -d "$d days" +"%Y-%m-%d")
            useradd -M -s /bin/false -e $e $u && echo "$u:$p" | chpasswd
            echo -e "${VERDE}Criado! Expira em: $e${SEM_COR}"; sleep 2; menu_principal ;;
        3) 
            echo -e "\nUUID ATUAL:"; grep "id" /usr/local/etc/xray/config.json
            echo -e "PORTAS ATIVAS:"; netstat -tpln | grep -E '80|443|22|7300'
            read -p "Pressione Enter..."; menu_principal ;;
        4)
            read -p "Nova Porta SSH: " ps
            sed -i "s/^Port .*/Port $ps/" /etc/ssh/sshd_config && systemctl restart ssh
            echo "Porta SSH alterada!"; sleep 2; menu_principal ;;
        0) exit ;;
        *) menu_principal ;;
    esac
}

menu_principal
