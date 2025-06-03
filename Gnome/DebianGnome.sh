#!/bin/bash

# ====================================
# 1. Atualizar Sistema
# ====================================
sudo apt update -y
sudo apt full-upgrade -y

# ====================================
# 2. Instalar Componentes Base (GNOME Mínimo)
# ====================================
sudo apt install -y gnome-shell gnome-control-center gdm3 kitty nautilus flatpak fish gir1.2-gtop-2.0 gir1.2-gmenu-3.0
sudo systemctl enable gdm3

# ====================================
# 3. Instalar VS Code
# ====================================
sudo apt-get install wget gpg
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
rm -f packages.microsoft.gpg
sudo apt install apt-transport-https
sudo apt update
sudo apt install code # or code-insiders


# ====================================
# 4. Instalar Pop Shell (Tiling)
# ====================================
sudo apt install -y node-typescript make git
TEMP_DIR=$(mktemp -d -t pop-shell-XXXXXX)
git clone https://github.com/pop-os/shell.git "${TEMP_DIR}/pop-shell"
cd "${TEMP_DIR}/pop-shell"
make local-install
cd - > /dev/null
rm -rf "${TEMP_DIR}"

# ====================================
# 5. Configurar Flatpak
# ====================================
sudo apt install -y flatpak # Garante que flatpak esteja instalado
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
sudo flatpak install -y flathub com.github.tchx84.Flatseal
sudo flatpak install -y flathub com.mattjakeman.ExtensionManager
sudo flatpak install -y flathub app.zen_browser.zen

# ====================================
# 6. Instalar Drivers NVIDIA (Opcional)
# ====================================
read -p "Você gostaria de instalar os drivers NVIDIA (versão 570.153.02)? (s/N): " INSTALL_NVIDIA_CHOICE # Variável de escolha diferente

if [[ "$INSTALL_NVIDIA_CHOICE" =~ ^[SsYy]$ ]]; then
    NVIDIA_DRIVER_URL="https://us.download.nvidia.com/XFree86/Linux-x86_64/570.153.02/NVIDIA-Linux-x86_64-570.153.02.run"
    NVIDIA_DRIVER_FILENAME=$(basename "${NVIDIA_DRIVER_URL}")
    TEMP_DIR_NVIDIA=$(mktemp -d -t nvidia-installer-XXXXXX) # Variável de diretório temporário diferente

    echo "Baixando o driver NVIDIA para ${TEMP_DIR_NVIDIA}..."
    wget -P "${TEMP_DIR_NVIDIA}" "${NVIDIA_DRIVER_URL}"
    
    if [ -f "${TEMP_DIR_NVIDIA}/${NVIDIA_DRIVER_FILENAME}" ]; then
        chmod +x "${TEMP_DIR_NVIDIA}/${NVIDIA_DRIVER_FILENAME}"
        echo "Driver NVIDIA baixado e permissão de execução concedida."
        echo "Por favor, siga as instruções do instalador NVIDIA."
        echo "Pode ser necessário sair da sessão gráfica atual."
        sudo "${TEMP_DIR_NVIDIA}/${NVIDIA_DRIVER_FILENAME}"
        echo "Instalação do driver NVIDIA concluída ou cancelada."
    else
        echo "Erro ao baixar o driver NVIDIA. Verifique a URL e sua conexão."
    fi

    echo "Limpando arquivos temporários do driver NVIDIA..."
    rm -rf "${TEMP_DIR_NVIDIA}"
else
    echo "Instalação do driver NVIDIA ignorada."
fi

echo "Script concluído."
echo "Pode ser necessário reiniciar o sistema para que todas as alterações tenham efeito."
