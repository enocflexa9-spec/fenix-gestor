#!/bin/bash

clear

REPO="https://raw.githubusercontent.com/enocflexa9-spec/fenix-gestor/main"
SCRIPT="fenix"

echo "========================================"
echo "      INSTALADOR FÊNIX GESTOR"
echo "========================================"
echo ""

# Verificar root
if [[ $EUID -ne 0 ]]; then
 echo "Execute como ROOT!"
 exit
fi

echo "Atualizando sistema..."

apt update -y
apt upgrade -y

echo ""
echo "Instalando dependências..."

apt install -y curl wget sudo

echo ""
echo "Baixando Fênix Gestor..."

wget -O /usr/local/bin/$SCRIPT $REPO/fenix.sh

chmod +x /usr/local/bin/$SCRIPT

echo ""
echo "Instalação concluída!"
echo ""
echo "Digite para abrir o painel:"
echo ""
echo "fenix"
echo ""