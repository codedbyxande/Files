#!/bin/bash

# ====================================
# 1. Atualizar Sistema
# ====================================
sudo pacman -Syu --noconfirm

# ====================================
# 2. Instalar Componentes Base (GNOME Mínimo)
# ====================================
sudo pacman -S --noconfirm plasma-desktop dolphin dolphin-plugins ffmpegthumbs ark kitty flatpak sddm-kcm sddm
sudo systemctl enable sddm

# ====================================
# 3. Instalar VS Code 
# ====================================
paru -S --noconfirm visual-studio-code-bin

# ====================================
# 4. Configurar Flatpak
# ====================================
sudo pacman -S --noconfirm flatpak # Garante que flatpak esteja instalado
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub com.github.tchx84.Flatseal
flatpak install -y flathub app.zen_browser.zen

# ====================================
# 6. Instalar Drivers NVIDIA (Opcional)
# Descomente as linhas abaixo se desejar instalar os drivers NVIDIA.
# Lembre-se de que os cabeçalhos do kernel devem estar instalados.
# ====================================
# sudo pacman -S --noconfirm nvidia-dkms nvidia-utils nvidia-settings
