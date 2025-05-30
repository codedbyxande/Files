#!/bin/bash

# ====================================
# 1. Atualizar Sistema
# ====================================
sudo dnf update -y

# ====================================
# 2. Instalar Componentes Base (GNOME Mínimo)
# ====================================
sudo dnf install -y @base-x @gnome-desktop gnome-shell gnome-control-center gdm kitty nautilus flatpak
sudo systemctl enable gdm

# ====================================
# 3. Instalar VS Code
# ====================================
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo dnf check-update
sudo dnf install -y code

# ====================================
# 4. Instalar Pop Shell (Tiling)
# ====================================
sudo dnf install -y nodejs npm typescript make git
TEMP_DIR=$(mktemp -d -t pop-shell-XXXXXX)
git clone https://github.com/pop-os/shell.git "${TEMP_DIR}/pop-shell"
cd "${TEMP_DIR}/pop-shell"
make local-install
cd - > /dev/null
rm -rf "${TEMP_DIR}"

# ====================================
# 5. Configurar Flatpak
# ====================================
sudo dnf install -y flatpak # Garante que flatpak esteja instalado
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub com.github.tchx84.Flatseal
flatpak install -y flathub com.mattjakeman.ExtensionManager
flatpak install -y flathub app.zen_browser.zen

# ====================================
# 6. Instalar Drivers NVIDIA (Opcional)
# Descomente as linhas abaixo se desejar instalar os drivers NVIDIA.
# ====================================
# sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
# sudo dnf update -y
# sudo dnf install -y akmod-nvidia
# sudo dnf install -y xorg-x11-drv-nvidia-cuda
