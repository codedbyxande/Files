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
            # Adiciona ou modifica as configurações diretamente no dnf.conf
            echo -e "${CYAN}Configurando max_parallel_downloads e fastestmirror no dnf.conf...${NC}"
            if ! grep -q "max_parallel_downloads=" /etc/dnf/dnf.conf; then
                run_cmd "sudo sed -i '/^\[main\]/a max_parallel_downloads=10' /etc/dnf/dnf.conf"
            else
                run_cmd "sudo sed -i 's/^max_parallel_downloads=.*/max_parallel_downloads=10/' /etc/dnf/dnf.conf"
            fi

            if ! grep -q "fastestmirror=" /etc/dnf/dnf.conf; then
                run_cmd "sudo sed -i '/^\[main\]/a fastestmirror=True' /etc/dnf/dnf.conf"
            else
                run_cmd "sudo sed -i 's/^fastestmirror=.*/fastestmirror=True/' /etc/dnf/dnf.conf"
            fi

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

# Instalar componentes base (GNOME Mínimo)
install_base() {
    echo -e "${CYAN}\n--- INSTALANDO COMPONENTES BASE (GNOME MÍNIMO) ---${NC}"
    case "$DISTRO" in
        fedora)
            run_cmd "sudo dnf install -y gnome-shell gnome-control-center gdm kitty nautilus flatpak"
            ;;
        cachyos)
            run_cmd "sudo pacman -S --noconfirm gnome-shell gnome-control-center gdm kitty nautilus flatpak"
            ;;
        debian*)
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
    # Instalação de dependências para Pop Shell
    case "$DISTRO" in
        fedora)
            run_cmd "sudo dnf install -y nodejs npm typescript make git"
            ;;
        cachyos)
            run_cmd "sudo pacman -S --noconfirm nodejs npm typescript make git"
            ;;
        debian*)
            run_cmd "sudo apt install -y nodejs npm typescript make git"
            ;;
    esac
    
    # Clonar, compilar e instalar o Pop Shell
    TEMP_DIR=$(mktemp -d -t pop-shell-XXXXXX)
    run_cmd "git clone https://github.com/pop-os/shell.git ${TEMP_DIR}/pop-shell"
    run_cmd "cd ${TEMP_DIR}/pop-shell"
    run_cmd "make local-install"
    run_cmd "cd -" # Volta para o diretório anterior
    run_cmd "rm -rf ${TEMP_DIR}" # Limpa o diretório temporário
}
install_pop_shell

# Configurar Flatpak
setup_flatpak() {
    echo -e "${CYAN}\n--- CONFIGURANDO FLATPAK ---${NC}"
    # Instala o pacote flatpak se ainda não estiver instalado para Debian
    if ([ "$DISTRO" == "debian_stable" ] || [ "$DISTRO" == "debian_sid" ]) && ! command -v flatpak &> /dev/null; then
        run_cmd "sudo apt install -y flatpak"
    fi

    run_cmd "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"
    run_cmd "flatpak install -y flathub com.github.tchx84.Flatseal"
    run_cmd "flatpak install -y flathub com.mattjakeman.ExtensionManager"
    
    # Instalação do Zen Browser (Flatpak para Fedora/Debian, AUR para CachyOS)
    if [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "debian_stable" ] || [ "$DISTRO" == "debian_sid" ]; then
        run_cmd "flatpak install -y flathub app.zen_browser.zen"
    elif [ "$DISTRO" == "cachyos" ]; then
        run_cmd "paru -S --noconfirm zen-browser-bin"
    fi
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
            # Habilita a seção non-free se ainda não estiver habilitada
            if ! grep -q "non-free" /etc/apt/sources.list; then
                echo -e "${CYAN}Adicionando 'non-free' aos repositórios APT...${NC}"
                # Para Sid, as fontes devem apontar para 'unstable'
                if [ "$DISTRO" == "debian_sid" ]; then
                    run_cmd "sudo sh -c 'echo \"deb http://deb.debian.org/debian/ unstable main contrib non-free\" > /etc/apt/sources.list'"
                    run_cmd "sudo sh -c 'echo \"deb-src http://deb.debian.org/debian/ unstable main contrib non-free\" >> /etc/apt/sources.list'"
                else # Debian Stable
                    run_cmd "sudo sed -i 's/ main$/ main contrib non-free/' /etc/apt/sources.list"
                    run_cmd "sudo sed -i 's/ main non-free-firmware$/ main contrib non-free non-free-firmware/' /etc/apt/sources.list"
                fi
                run_cmd "sudo apt update -y"
            fi
            run_cmd "sudo apt install -y nvidia-driver firmware-misc-nonfree"
            echo -e "${YELLOW}Após a instalação dos drivers NVIDIA, é **altamente recomendado** reiniciar o sistema para que as alterações entrem em vigor.${NC}"
            ;;
    esac
}
install_nvidia

echo -e "${GREEN}\n✅ Configuração concluída! Reinicie o sistema.${NC}"
echo -e "${YELLOW}Erros registrados em: ${LOG_FILE}${NC}"
