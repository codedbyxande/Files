#!/bin/bash

# ====================================
# 1. Atualizar Sistema
# ====================================
sudo apt update -y
sudo apt full-upgrade -y

# ====================================
# 2. Instalar Componentes Base (GNOME Mínimo)
# ====================================
sudo apt install -y gnome flatpak fish gir1.2-gtop-2.0 gir1.2-gmenu-3.0
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
read -p "Deseja instalar os drivers NVIDIA? (s/N): " install_nvidia
if [[ "$install_nvidia" =~ ^[Ss]$ ]]; then
    sudo sed -i 's/ main$/ main contrib non-free/' /etc/apt/sources.list
    sudo sed -i 's/ main non-free-firmware$/ main contrib non-free non-free-firmware/' /etc/apt/sources.list
    sudo apt update -y
    sudo apt install -y nvidia-driver firmware-misc-nonfree linux-headers-amd64
fi
