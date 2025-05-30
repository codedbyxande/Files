#!/bin/bash
set -e

# Cores
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

# Arquivo de log de erros
LOG_FILE="$(dirname "$0")/setup_errors.log"
echo "===== LOG DE ERROS - $(date) =====" > "$LOG_FILE"

# Função para registrar erros
log_error() {
    local message="$1"
    echo -e "${RED}${message}${NC}"
    echo "ERRO: ${message}" >> "$LOG_FILE"
}

# Função para executar comandos com tratamento de erro
run_cmd() {
    local cmd="$*"
    echo -e "${CYAN}Executando: ${cmd}${NC}"
    if ! eval "$cmd" >> "$LOG_FILE" 2>&1; then
        log_error "Falha ao executar: ${cmd}"
        return 1
    fi
    return 0
}

echo -e "${CYAN}\n===== INICIANDO CONFIGURAÇÃO DO SISTEMA =====${NC}"

# Detectar distribuição
detect_distro() {
    if grep -qi "fedora" /etc/os-release; then
        echo "fedora"
    elif grep -qi "cachyos" /etc/os-release || grep -qi "arch" /etc/os-release; then
        echo "cachyos"
    elif grep -qi "debian" /etc/os-release; then
        if grep -q "sid" /etc/apt/sources.list || grep -q "unstable" /etc/debian_version; then
            echo "debian_sid"
        else
            echo "debian_stable"
        fi
    else
        echo "unknown"
    fi
}

DISTRO=$(detect_distro)

if [ "$DISTRO" == "unknown" ]; then
    log_error "Distribuição não suportada!"
    exit 1
fi

echo -e "${CYAN}Detectado: ${DISTRO^^}${NC}"

# Aviso para Debian Sid
if [ "$DISTRO" == "debian_sid" ]; then
    echo -e "${YELLOW}\nAVISO: Debian Sid (Unstable) pode ter problemas!${NC}"
    read -r -p "Continuar? [s/N]: " confirm
    [[ ! "$confirm" =~ ^[Ss]$ ]] && exit 1
fi

# Atualizar sistema
update_system() {
    echo -e "${CYAN}\n--- ATUALIZANDO SISTEMA ---${NC}"
    case "$DISTRO" in
        fedora)
            run_cmd "sudo dnf config-manager --setopt=max_parallel_downloads=10 --save"
            run_cmd "sudo dnf config-manager --setopt=fastestmirror=True --save"
            run_cmd "sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
            run_cmd "sudo dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
            run_cmd "sudo dnf update -y"
            ;;
        cachyos)
            run_cmd "sudo pacman -Syu --noconfirm"
            # Instalar paru (AUR helper) se necessário
            command -v paru >/dev/null || {
                run_cmd "sudo pacman -S --noconfirm base-devel git"
                run_cmd "git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-bin"
                run_cmd "cd /tmp/paru-bin && makepkg -si --noconfirm"
            }
            ;;
        debian*)
            [ "$DISTRO" == "debian_sid" ] && run_cmd "sudo sed -i 's/main.*/main contrib non-free/g' /etc/apt/sources.list"
            run_cmd "sudo apt update -y"
            run_cmd "sudo apt full-upgrade -y"
            ;;
    esac
}
update_system

# Instalar componentes base
install_base() {
    echo -e "${CYAN}\n--- INSTALANDO COMPONENTES BASE ---${NC}"
    case "$DISTRO" in
        fedora)
            run_cmd "sudo dnf install -y @base-x gnome-shell gnome-control-center gdm kitty nautilus flatpak"
            ;;
        cachyos)
            run_cmd "sudo pacman -S --noconfirm gnome-shell gnome-control-center gdm kitty nautilus flatpak"
            ;;
        debian*)
            run_cmd "sudo apt install -y tasksel"
            run_cmd "sudo tasksel install gnome-desktop"
            run_cmd "sudo apt install -y gnome-shell gnome-control-center gdm kitty nautilus flatpak"
            ;;
    esac
    run_cmd "sudo systemctl enable gdm"
}
install_base

# Instalar VS Code
install_vscode() {
    echo -e "${CYAN}\n--- INSTALANDO VS CODE ---${NC}"
    case "$DISTRO" in
        fedora)
            run_cmd "sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc"
            run_cmd "sudo sh -c 'echo -e \"[code]\nname=VS Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\" > /etc/yum.repos.d/vscode.repo'"
            run_cmd "sudo dnf install -y code"
            ;;
        cachyos)
            run_cmd "paru -S --noconfirm visual-studio-code-bin"
            ;;
        debian*)
            run_cmd "curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg"
            run_cmd "echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main\" | sudo tee /etc/apt/sources.list.d/vscode.list"
            run_cmd "sudo apt update"
            run_cmd "sudo apt install -y code"
            ;;
    esac
}
install_vscode

# Instalar Pop Shell (Tiling)
install_pop_shell() {
    echo -e "${CYAN}\n--- INSTALANDO POP SHELL ---${NC}"
    case "$DISTRO" in
        fedora|debian*)
            run_cmd "git clone https://github.com/pop-os/shell.git /tmp/pop-shell"
            run_cmd "cd /tmp/pop-shell"
            run_cmd "make local-install"
            ;;
        cachyos)
            run_cmd "paru -S --noconfirm gnome-shell-extension-pop-shell"
            ;;
    esac
}
install_pop_shell

# Configurar Flatpak
setup_flatpak() {
    echo -e "${CYAN}\n--- CONFIGURANDO FLATPAK ---${NC}"
    run_cmd "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"
    run_cmd "flatpak install -y flathub com.github.tchx84.Flatseal"
    run_cmd "flatpak install -y flathub com.mattjakeman.ExtensionManager"
    run_cmd "flatpak install -y flathub app.zen_browser.zen"
}
setup_flatpak

# Instalar drivers NVIDIA
install_nvidia() {
    read -r -p "$(echo -e "${YELLOW}Instalar drivers NVIDIA? [s/N]: ${NC}")" confirm
    [[ ! "$confirm" =~ ^[Ss]$ ]] && return
    
    echo -e "${CYAN}\n--- INSTALANDO DRIVERS NVIDIA ---${NC}"
    case "$DISTRO" in
        fedora)
            run_cmd "sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda"
            ;;
        cachyos)
            run_cmd "sudo pacman -S --noconfirm nvidia-dkms nvidia-utils"
            ;;
        debian*)
            run_cmd "sudo apt install -y nvidia-driver firmware-misc-nonfree"
            ;;
    esac
}
install_nvidia

echo -e "${GREEN}\n✅ Configuração concluída! Reinicie o sistema.${NC}"
echo -e "${YELLOW}Erros registrados em: ${LOG_FILE}${NC}"
