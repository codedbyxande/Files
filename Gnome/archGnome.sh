#!/bin/bash

# ====================================
# 1. Atualizar Sistema
# ====================================
sudo pacman -Syu --noconfirm

# ====================================
# 2. Instalar Componentes Base (GNOME Mínimo)
# ====================================
sudo pacman -S --noconfirm gnome flatpak
sudo pacman -S --noconfirm hyprland rofi-wayland nwg-lock nwg-displays pop-icon-theme
sudo systemctl enable gdm

# ====================================
# 3. Instalar VS Code 
# ====================================
paru -S --noconfirm visual-studio-code-bin

# ====================================
# 4. Instalar Pop Shell (Tiling)
# ====================================
sudo pacman -S --noconfirm nodejs npm typescript make git
TEMP_DIR=$(mktemp -d -t pop-shell-XXXXXX)
git clone https://github.com/pop-os/shell.git "${TEMP_DIR}/pop-shell"
cd "${TEMP_DIR}/pop-shell"
make local-install
cd - > /dev/null
rm -rf "${TEMP_DIR}"

# ====================================
# 5. Configurar Flatpak
# ====================================
sudo pacman -S --noconfirm flatpak # Garante que flatpak esteja instalado
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub com.github.tchx84.Flatseal
flatpak install -y flathub com.mattjakeman.ExtensionManager
flatpak install -y flathub app.zen_browser.zen

# ====================================
# 6. Instalar Drivers NVIDIA (Opcional)
# Descomente as linhas abaixo se desejar instalar os drivers NVIDIA.
# Lembre-se de que os cabeçalhos do kernel devem estar instalados.
# ====================================
 sudo pacman -S --noconfirm nvidia-dkms nvidia-utils nvidia-settings cuda
