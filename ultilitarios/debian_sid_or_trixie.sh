#!/bin/bash

function error_exit {
    echo "Erro: $1" >&2
    exit 1
}

if [ "$(id -u)" -ne 0 ]; then
    error_exit "Este script precisa ser executado como root. Use 'sudo'."
fi

read -p "Você fez um backup completo dos seus dados? (s/n): " backup_confirm
if [[ ! "$backup_confirm" =~ ^[Ss]$ ]]; then
    error_exit "Por favor, faça um backup dos seus dados antes de continuar. Script abortado."
fi

echo "Escolha a versão do Debian para a qual deseja apontar o sources.list:"
echo "  1) Debian 13 Trixie (Testing)"
echo "  2) Debian Sid (Unstable)"
read -p "Digite 1 ou 2: " choice

case $choice in
    1)
        TARGET_RELEASE="trixie"
        ;;
    2)
        TARGET_RELEASE="sid"
        ;;
    *)
        error_exit "Opção inválida. Digite 1 ou 2."
        ;;
esac

cp /etc/apt/sources.list /etc/apt/sources.list.bak || error_exit "Falha ao fazer backup do sources.list."

cat > /etc/apt/sources.list <<EOF
deb http://deb.debian.org/debian/ $TARGET_RELEASE main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ $TARGET_RELEASE main contrib non-free non-free-firmware

deb http://security.debian.org/debian-security $TARGET_RELEASE-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security $TARGET_RELEASE-security main contrib non-free non-free-firmware

deb http://deb.debian.org/debian/ $TARGET_RELEASE-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ $TARGET_RELEASE-updates main contrib non-free non-free-firmware
EOF

echo "/etc/apt/sources.list configurado para $TARGET_RELEASE."
echo "Agora, atualize seu sistema manualmente com:"
echo "  sudo apt update"
echo "  sudo apt upgrade"
echo "  sudo apt full-upgrade"
echo "  sudo apt autoremove"
