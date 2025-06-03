#!/bin/bash

# Garante que o script seja executado como root
if [ "$(id -u)" -ne 0 ]; then
  echo "Erro: Este script precisa ser executado como root. Use 'sudo'." >&2
  exit 1
fi

# Faz backup do sources.list existente
# Em caso de falha, exibe uma mensagem de erro e sai.
cp /etc/apt/sources.list /etc/apt/sources.list.bak || { echo "Erro: Falha ao fazer backup do sources.list." >&2; exit 1; }

# Cria o novo sources.list com os repositórios especificados
cat > /etc/apt/sources.list <<EOF
deb http://deb.debian.org/debian/ trixie main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ trixie main contrib non-free non-free-firmware

deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
EOF

echo "/etc/apt/sources.list configurado para Debian Trixie."
echo "Agora, execute 'sudo apt update && sudo apt full-upgrade' para atualizar seu sistema."
