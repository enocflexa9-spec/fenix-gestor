#!/bin/bash
# ==========================================
# FÊNIX GESTOR v8.0 - FULL PANEL
# ==========================================

# Cores
VERDE='\033[1;32m'; VERMELHO='\033[1;31m'; AMARELO='\033[1;33m'; AZUL='\033[1;34m'; SEM_COR='\033[0m'

# Verificar Root
[[ "$EUID" -ne 0 ]] && echo "Execute como root!" && exit 1

# --- GERENCIADOR SSH (USUÁRIO, SENHA, DATA) ---
menu_ssh() {
    clear
    echo -e "${AZUL}>>> GERENCIADOR SSH <<<${SEM_COR}"
    echo -e "1) Criar Usuário (Com Validade)"
    echo -e "2) Deletar Usuário"
    echo -e "3) Listar Usuários Online"
    echo -e "0) Voltar"
    read -p "Opção: " op
    case $op in
        1)
            read -p "Nome: " user
            read -p "Senha: " pass
            read -p "Dias: " dias
            exp=$(date -d "$dias days" +"%Y-%m-%d")
            useradd -M -s /bin/false -e $exp $user
            echo "$user:$pass" | chpasswd
            echo -e "${VERDE}Usuário $user criado até $exp!${SEM_COR}"; sleep 2; menu_ssh ;;
        2)
            read -p "Nome para remover: " user
            userdel -f $user
            echo -e "${VERMELHO}Removido!${SEM_COR}"; sleep 2; menu_ssh ;;
        3)
            echo -e "\n${AMARELO}CONEXÕES ATIVAS:${SEM_COR}"
            ps aux | grep -i sshd | grep -v grep
            read -p "Pressione Enter..."; menu_ssh ;;
        0) menu_principal ;;
    esac
}

# --- GERENCIADOR DE PORTAS (WS, UDP, SOCKS) ---
menu_portas() {
    clear
    echo -e "${AZUL}>>> GERENCIADOR DE PORTAS <<<${SEM_COR}"
    echo -e "1) Alterar Porta WebSocket (80)"
    echo -e "2) Alterar Porta BadVPN (UDP 7300)"
    echo -e "3) Alterar Porta SSH/Socks (22)"
    echo -e "0) Voltar"
    read -p "Opção: " op
    case $op in
        1)
            read -p "Nova Porta WS: " p
            pkill -f fenix-ws.py
            # Comando para rodar o WS na nova porta
            screen -dmS fenix-ws python3 /usr/local/bin/fenix-ws.py $p
            echo -e "${VERDE}Porta $p ativada!${SEM_COR}"; sleep 2; menu_portas ;;
        2)
            read -p "Nova Porta UDP: " p
            pkill badvpn-udpgw
            screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:$p
            echo -e "${VERDE}UDP rodando na porta $p!${SEM_COR}"; sleep 2; menu_portas ;;
        3)
            read -p "Nova Porta SSH: " p
            sed -i "s/^Port .*/Port $p/" /etc/ssh/sshd_config
            systemctl restart ssh
            echo -e "${VERDE}SSH/Socks alterado para $p!${SEM_COR}"; sleep 2; menu_portas ;;
        0) menu_principal ;;
    esac
}

# --- GERENCIADOR XRAY ---
menu_xray() {
    clear
    echo -e "${AZUL}>>> GERENCIADOR XRAY <<<${SEM_COR}"
    echo -e "1) Ver UUID / Config JSON"
    echo -e "2) Gerar Novo UUID"
    echo -e "0) Voltar"
    read -p "Opção: " op
    case $op in
        1) cat /usr/local/etc/xray/config.json; read -p "Enter..."; menu_xray ;;
        2) 
            id=$(cat /proc/sys/kernel/random/uuid)
            sed -i "s/\"id\": \".*\"/\"id\": \"$id\"/" /usr/local/etc/xray/config.json
            systemctl restart xray
            echo -e "${VERDE}Novo UUID: $id${SEM_COR}"; sleep 3; menu_xray ;;
        0) menu_principal ;;
    esac
}

# --- MENU PRINCIPAL ---
menu_principal() {
    clear
    echo -e "${VERDE}=========================================${SEM_COR}"
    echo -e "          FENIX GESTOR v8.0 PRO          "
    echo -e "${VERDE}=========================================${SEM_COR}"
    echo -e "${AMARELO}[1]${SEM_COR} GERENCIAR SSH / USUÁRIOS"
    echo -e "${AMARELO}[2]${SEM_COR} GERENCIAR PORTAS (WS/UDP/SOCKS)"
    echo -e "${AMARELO}[3]${SEM_COR} GERENCIAR XRAY / VMESS"
    echo -e "${AMARELO}[0]${SEM_COR} SAIR"
    read -p "Escolha: " opt
    case $opt in
        1) menu_ssh ;;
        2) menu_portas ;;
        3) menu_xray ;;
        0) exit ;;
        *) menu_principal ;;
    esac
}

menu_principal
