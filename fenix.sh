#!/bin/bash
# ==========================================
# FÊNIX GESTOR v1.0 - GITHUB OFFICIAL
# ==========================================

VERDE='\e[32m'; VERMELHO='\e[31m'; AMARELO='\e[33m'; AZUL='\e[34m'; SEM_COR='\e[0m'

# --- GERENCIADOR SSH (USUÁRIO, SENHA, DATA) ---
menu_ssh() {
    clear
    echo -e "${AZUL}=========================================${SEM_COR}"
    echo -e "          GERENCIADOR DE USUÁRIOS        "
    echo -e "${AZUL}=========================================${SEM_COR}"
    echo -e "1) Criar Usuário VPN"
    echo -e "2) Deletar Usuário"
    echo -e "3) Listar Usuários e Validade"
    echo -e "0) Voltar"
    read -p "Escolha: " op_ssh
    case $op_ssh in
        1)
            read -p "Nome do Usuário: " user
            read -p "Senha: " pass
            read -p "Dias de validade: " dias
            data_exp=$(date -d "$dias days" +"%Y-%m-%d")
            useradd -M -s /bin/false -e $data_exp $user
            echo "$user:$pass" | chpasswd
            echo -e "${VERDE}Usuário $user criado! Expira em: $data_exp${SEM_COR}"; sleep 3; menu_ssh ;;
        2)
            read -p "Usuário para remover: " user
            userdel -f $user
            echo -e "${VERMELHO}Usuário removido!${SEM_COR}"; sleep 2; menu_ssh ;;
        3)
            echo -e "\n${AMARELO}LISTA DE USUÁRIOS E EXPIRAÇÃO:${SEM_COR}"
            for user in $(awk -F: '$3 >= 1000 {print $1}' /etc/passwd | grep -v "nobody"); do
                expiracao=$(chage -l $user | grep "Account expires" | cut -d: -f2)
                echo -e "Usuário: $user | Expira em: $expiracao"
            done
            read -p "Pressione Enter..."; menu_ssh ;;
        0) menu_principal ;;
    esac
}

# --- GERENCIADOR DE PORTAS (WEBSOCKET / BADVPN / SOCKS) ---
menu_portas() {
    clear
    echo -e "${AZUL}>>> GERENCIADOR DE PORTAS <<<${SEM_COR}"
    echo -e "1) Mudar Porta WebSocket (Atual: 80)"
    echo -e "2) Mudar Porta BadVPN/UDP (Atual: 7300)"
    echo -e "3) Mudar Porta Proxy Socks (SSH)"
    echo -e "0) Voltar"
    read -p "Opção: " op_p
    case $op_p in
        1)
            read -p "Nova Porta WS: " p_ws
            pkill -f fenix-ws.py
            sed -i "s/server.bind(('0.0.0.0', [0-9]*))/server.bind(('0.0.0.0', $p_ws))/" /usr/local/bin/fenix-ws.py
            screen -dmS fenix-ws python3 /usr/local/bin/fenix-ws.py
            echo -e "${VERDE}Porta WS alterada!${SEM_COR}"; sleep 2; menu_portas ;;
        2)
            read -p "Nova Porta UDP: " p_udp
            pkill badvpn-udpgw
            screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:$p_udp
            echo -e "${VERDE}Porta UDP alterada!${SEM_COR}"; sleep 2; menu_portas ;;
        3)
            echo "A porta Socks padrão é a do SSH (22)."
            read -p "Nova porta SSH/Socks: " p_ssh
            sed -i "s/^Port .*/Port $p_ssh/" /etc/ssh/sshd_config
            service ssh restart
            echo -e "${VERDE}Porta Socks/SSH alterada!${SEM_COR}"; sleep 2; menu_portas ;;
        0) menu_principal ;;
    esac
}

# --- GERENCIADOR XRAY (UUID E CONFIG) ---
menu_xray() {
    clear
    echo -e "${AZUL}>>> GERENCIADOR XRAY / VMESS <<<${SEM_COR}"
    echo -e "1) Ver UUID Atual"
    echo -e "2) Gerar Novo UUID"
    echo -e "3) Ver Configuração JSON Completa"
    echo -e "0) Voltar"
    read -p "Opção: " op_xr
    case $op_xr in
        1) 
            uuid_atual=$(grep "id" /usr/local/etc/xray/config.json | awk -F'"' '{print $4}')
            echo -e "UUID Atual: ${AMARELO}$uuid_atual${SEM_COR}"
            read -p "Enter para continuar..."; menu_xray ;;
        2) 
            new_id=$(cat /proc/sys/kernel/random/uuid)
            sed -i "s/\"id\": \".*\"/\"id\": \"$new_id\"/" /usr/local/etc/xray/config.json
            systemctl restart xray
            echo -e "${VERDE}Novo UUID Gerado: $new_id${SEM_COR}"; sleep 3; menu_xray ;;
        3)
            cat /usr/local/etc/xray/config.json
            read -p "Pressione Enter..."; menu_xray ;;
        0) menu_principal ;;
    esac
}

# --- MENU PRINCIPAL ---
menu_principal() {
    clear
    echo -e "${VERDE}=========================================${SEM_COR}"
    echo -e "          FENIX GESTOR v7.0 PRO          "
    echo -e "${VERDE}=========================================${SEM_COR}"
    echo -e "${AMARELO}[1]${SEM_COR} GERENCIAR USUÁRIOS SSH"
    echo -e "${AMARELO}[2]${SEM_COR} GERENCIAR PORTAS (WS/UDP/SOCKS)"
    echo -e "${AMARELO}[3]${SEM_COR} GERENCIAR XRAY (UUID/CONFIG)"
    echo -e "${AMARELO}[4]${SEM_COR} REINICIAR TUDO"
    echo -e "${AMARELO}[0]${SEM_COR} SAIR"
    echo -e "${VERDE}=========================================${SEM_COR}"
    read -p "Escolha: " opt
    case $opt in
        1) menu_ssh ;;
        2) menu_portas ;;
        3) menu_xray ;;
        4) systemctl restart ssh xray; pkill -f fenix-ws.py; screen -dmS fenix-ws python3 /usr/local/bin/fenix-ws.py; echo "OK"; sleep 2; menu_principal ;;
        0) exit ;;
        *) menu_principal ;;
    esac
}

menu_principal
