#!/bin/bash

# ====================================
# 1. Atualizar Sistema
# ====================================
sudo dnf update -y

# ====================================
# 2. Instalar Componentes Base (KDE Mínimo)
# ====================================
sudo dnf install -y plasma-desktop dolphin dolphin-plugins ffmpegthumbs ark kitty  flatpak
sudo dnf install -y hyprland hyprland-devel rofi-wayland
sudo systemctl set-default graphical.target
sudo systemctl enable sddm

# ====================================
# 3. Instalar VS Code
# ====================================
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo dnf check-update
sudo dnf install -y code

# ====================================
# 4. Configurar Flatpak
# ====================================
sudo dnf install -y flatpak # Garante que flatpak esteja instalado
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub com.github.tchx84.Flatseal
flatpak install -y flathub com.mattjakeman.ExtensionManager
flatpak install -y flathub app.zen_browser.zen

# ====================================
# 5. Instalar Drivers NVIDIA (Opcional)
# ====================================
read -p "Deseja instalar os drivers NVIDIA? (s/N): " install_nvidia
if [[ "$install_nvidia" =~ ^[Ss]$ ]]; then
    sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf update -y
    sudo dnf install -y akmod-nvidia
    sudo dnf install -y xorg-x11-drv-nvidia-cuda
fi


