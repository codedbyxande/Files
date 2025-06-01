#!/bin/bash

# ====================================
# 1. Atualizar Sistema
# ====================================
sudo apt update -y
sudo apt full-upgrade -y

# ====================================
# 2. Instalar Componentes Base (GNOME Mínimo)
# ====================================
sudo apt install -y gnome-shell gnome-control-center gdm3 kitty flatpak
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
# 4. Configurar Flatpak
# ====================================
sudo apt install -y flatpak # Garante que flatpak esteja instalado
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub com.github.tchx84.Flatseal
flatpak install -y flathub com.mattjakeman.ExtensionManager
flatpak install -y flathub app.zen_browser.zen

# ====================================
# 6. Instalar Drivers NVIDIA (Opcional)
# ====================================
read -p "Deseja instalar os drivers NVIDIA? (s/N): " install_nvidia
if [[ "$install_nvidia" =~ ^[Ss]$ ]]; then
    sudo sed -i 's/ main$/ main contrib non-free/' /etc/apt/sources.list
    sudo sed -i 's/ main non-free-firmware$/ main contrib non-free non-free-firmware/' /etc/apt/sources.list
    sudo apt update -y
    sudo apt install -y nvidia-driver firmware-misc-nonfree
fi
