#!/bin/bash

# ====================================
# 1. Atualizar Sistema
# ====================================
sudo apt update -y
sudo apt full-upgrade -y

# ====================================
# 2. Instalar Componentes Base (GNOME Mínimo)
# ====================================
sudo apt install -y gnome-shell gnome-control-center gdm kitty nautilus flatpak
sudo systemctl enable gdm

# ====================================
# 3. Instalar VS Code
# ====================================
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
sudo apt update
sudo apt install -y code

# ====================================
# 4. Instalar Pop Shell (Tiling)
# ====================================
sudo apt install -y nodejs npm typescript make git
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
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub com.github.tchx84.Flatseal
flatpak install -y flathub com.mattjakeman.ExtensionManager
flatpak install -y flathub app.zen_browser.zen

# ====================================
# 6. Instalar Drivers NVIDIA (Opcional)
# Descomente as linhas abaixo se desejar instalar os drivers NVIDIA.
# Certifique-se de que a seção 'non-free' esteja habilitada no seu sources.list.
# ====================================
# sudo sed -i 's/ main$/ main contrib non-free/' /etc/apt/sources.list
# sudo sed -i 's/ main non-free-firmware$/ main contrib non-free non-free-firmware/' /etc/apt/sources.list
# sudo apt update -y
# sudo apt install -y nvidia-driver firmware-misc-nonfree
