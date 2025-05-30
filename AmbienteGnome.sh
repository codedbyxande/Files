#!/bin/bash
set -e

# Cores
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

echo -e "${CYAN}\n===== INICIANDO CONFIGURAÇÃO DO SISTEMA (DEBIAN SID) =====${NC}"

# Função para detectar a distribuição
detect_distro() {
    if grep -q "Fedora" /etc/os-release; then
        echo "fedora"
    elif grep -q "CachyOS" /etc/os-release || grep -q "Arch Linux" /etc/os-release; then
        echo "cachyos"
    elif grep -q "Debian" /etc/os-release; then
        # Verifica se é Sid
        if grep -q "unstable" /etc/debian_version || grep -q "sid" /etc/apt/sources.list; then
            echo "debian_sid"
        else
            echo "debian_stable" # Manteve a distinção para futuras expansões ou caso o usuário rode em stable
        fi
    else
        echo "unknown"
    fi
}

DISTRO=$(detect_distro)

if [ "$DISTRO" == "unknown" ]; then
    echo -e "${RED}Distribuição não suportada. Este script funciona apenas para Fedora, CachyOS/Arch Linux e Debian.${NC}"
    exit 1
fi

echo -e "${CYAN}Detectado: ${DISTRO^^}${NC}" # Imprime a distribuição detectada em maiúsculas

# Aviso para Debian Sid
if [ "$DISTRO" == "debian_sid" ]; then
    echo -e "${YELLOW}\nAVISO: Você está executando este script no Debian Sid (Unstable).${NC}"
    echo -e "${YELLOW}O Sid pode ser instável e quebrar ocasionalmente. Prossiga com cautela.${NC}"
    read -r -p "$(echo -e "${YELLOW}Deseja continuar? [s/N]: ${NC}")" confirm_sid
    if [[ ! "$confirm_sid" =~ ^[Ss]$ ]]; then
        echo -e "${RED}Operação cancelada pelo usuário.${NC}"
        exit 1
    fi
fi

### Configuração e Atualização do Sistema (Específico da Distro)

if [ "$DISTRO" == "fedora" ]; then
    echo -e "${CYAN}\n--- CONFIGURANDO DNF ---${NC}"
    sudo tee -a /etc/dnf/dnf.conf > /dev/null <<EOF
max_parallel_downloads=10
fastestmirror=True
EOF

    echo -e "${CYAN}\n--- ADICIONANDO RPM FUSION ---${NC}"
    sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || { echo -e "${YELLOW}Falha ao adicionar RPM Fusion. Continuando.${NC}"; }

    echo -e "${CYAN}\n--- ATUALIZANDO O SISTEMA (DNF) ---${NC}"
    sudo dnf update -y && sudo dnf upgrade -y || { echo -e "${YELLOW}Falha ao atualizar o sistema DNF. Continuando.${NC}"; }

elif [ "$DISTRO" == "cachyos" ]; then
    echo -e "${CYAN}\n--- ATUALIZANDO O SISTEMA (PACMAN) ---${NC}"
    sudo pacman -Syu --noconfirm || { echo -e "${YELLOW}Falha ao atualizar o sistema Pacman. Continuando.${NC}"; }

    # Garante que o paru esteja instalado para CachyOS/Arch
    if ! command -v paru &> /dev/null; then
        echo -e "${CYAN}\n--- INSTALANDO PARU ---${NC}"
        sudo pacman -S --noconfirm base-devel || { echo -e "${YELLOW}Falha ao instalar base-devel para paru. Continuando.${NC}"; }
        git clone https://aur.archlinux.org/paru.git /tmp/paru || { echo -e "${YELLOW}Falha ao clonar paru. Continuando.${NC}"; }
        (cd /tmp/paru && makepkg -si --noconfirm) || { echo -e "${YELLOW}Falha ao compilar e instalar paru. Continuando.${NC}"; }
        rm -rf /tmp/paru
    fi
elif [ "$DISTRO" == "debian_stable" ] || [ "$DISTRO" == "debian_sid" ]; then
    echo -e "${CYAN}\n--- ATUALIZANDO O SISTEMA (APT) ---${NC}"
    # Para Debian Sid, garantir que as fontes sejam 'sid' ou 'unstable'
    if [ "$DISTRO" == "debian_sid" ]; then
        echo -e "${CYAN}Configurando fontes APT para Debian Sid...${NC}"
        sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup_$(date +%Y%m%d%H%M%S)
        echo "deb http://deb.debian.org/debian/ unstable main contrib non-free" | sudo tee /etc/apt/sources.list > /dev/null
        echo "deb-src http://deb.debian.org/debian/ unstable main contrib non-free" | sudo tee -a /etc/apt/sources.list > /dev/null
        # Opcional: Adicionar security updates para Sid se o usuário quiser, embora geralmente não seja mantido ativamente.
        # echo "deb http://security.debian.org/debian-security unstable/updates main contrib non-free" | sudo tee -a /etc/apt/sources.list > /dev/null
    fi
    sudo apt update -y && sudo apt upgrade -y || { echo -e "${YELLOW}Falha ao atualizar o sistema APT. Verifique suas fontes e conectividade.${NC}"; }
fi

### Instalação de Aplicativos Essenciais (Geral, com adaptação para VS Code e Zen Browser)

echo -e "${CYAN}\n--- INSTALANDO VS CODE ---${NC}"
if [ "$DISTRO" == "fedora" ]; then
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
    dnf check-update
    sudo dnf install -y code || { echo -e "${YELLOW}Falha ao instalar VS Code no Fedora. Continuando.${NC}"; }
elif [ "$DISTRO" == "cachyos" ]; then
    paru -S --noconfirm visual-studio-code-bin || { echo -e "${YELLOW}Falha ao instalar VS Code no CachyOS. Continuando.${NC}"; }
elif [ "$DISTRO" == "debian_stable" ] || [ "$DISTRO" == "debian_sid" ]; then
    # Garante que 'curl' e 'gnupg' estejam instalados para adicionar chaves e repositórios
    sudo apt install -y curl gnupg || { echo -e "${YELLOW}Falha ao instalar curl/gnupg. VS Code pode não ser instalado.${NC}"; }

    # Adiciona a chave GPG da Microsoft
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/microsoft.gpg
    sudo chmod 644 /etc/apt/trusted.gpg.d/microsoft.gpg

    # Adiciona o repositório do VS Code
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    sudo apt update -y
    sudo apt install -y code || { echo -e "${YELLOW}Falha ao instalar VS Code no Debian. Continuando.${NC}"; }
fi

echo -e "${CYAN}\n--- INSTALANDO GNOME MÍNIMO ---${NC}"
if [ "$DISTRO" == "fedora" ]; then
    sudo dnf install -y gnome-shell gnome-control-center gdm kitty nautilus flatpak gnome-tweaks || { echo -e "${YELLOW}Falha ao instalar componentes GNOME no Fedora. Continuando.${NC}"; }
    sudo systemctl set-default graphical.target
elif [ "$DISTRO" == "cachyos" ]; then
    sudo pacman -S --noconfirm gnome-shell flatpak gnome-control-center gdm kitty nautilus gnome-tweaks || { echo -e "${YELLOW}Falha ao instalar componentes GNOME no CachyOS. Continuando.${NC}"; }
elif [ "$DISTRO" == "debian_stable" ] || [ "$DISTRO" == "debian_sid" ]; then
    # Instala o Tasksel para facilitar a instalação do ambiente GNOME
    sudo apt install -y tasksel || { echo -e "${YELLOW}Falha ao instalar tasksel. O ambiente GNOME pode não ser instalado corretamente.${NC}"; }
    # Usa --new-install para evitar conflitos se já houver algo
    sudo tasksel install gnome-desktop --new-install || { echo -e "${YELLOW}Falha ao instalar GNOME Desktop via tasksel. Continuando.${NC}"; }
    # Instala aplicativos adicionais explicitamente que podem não vir com gnome-desktop ou são preferidos
    sudo apt install -y gnome-shell gnome-control-center gdm kitty nautilus flatpak gnome-tweaks || { echo -e "${YELLOW}Falha ao instalar componentes GNOME adicionais no Debian. Continuando.${NC}"; }
fi
sudo systemctl enable gdm || { echo -e "${YELLOW}Falha ao habilitar GDM. Você pode precisar habilitá-lo manualmente.${NC}"; }

echo -e "${CYAN}\n--- INSTALANDO POP SHELL ---${NC}"
if [ "$DISTRO" == "fedora" ]; then
    sudo dnf install -y nodejs npm typescript make git || { echo -e "${YELLOW}Falha ao instalar dependências do Pop Shell no Fedora. O Pop Shell pode não ser instalado.${NC}"; }
elif [ "$DISTRO" == "cachyos" ]; then
    sudo pacman -S --noconfirm nodejs npm typescript make git || { echo -e "${YELLOW}Falha ao instalar dependências do Pop Shell no CachyOS. O Pop Shell pode não ser instalado.${NC}"; }
elif [ "$DISTRO" == "debian_stable" ] || [ "$DISTRO" == "debian_sid" ]; then
    # No Debian, o pacote Node.js pode ser 'nodejs' e o npm separadamente, ou apenas 'nodejs' que inclui npm.
    # Garante que os pacotes necessários estejam disponíveis
    sudo apt install -y nodejs npm typescript make git || { echo -e "${YELLOW}Falha ao instalar dependências do Pop Shell no Debian. O Pop Shell pode não ser instalado.${NC}"; }
fi

TEMP_DIR=$(mktemp -d -t pop-shell-XXXXXX)
echo -e "${CYAN}Criado diretório temporário: ${TEMP_DIR}${NC}"
if cd "${TEMP_DIR}"; then
    echo -e "${CYAN}Clonando o repositório Pop Shell...${NC}"
    if git clone https://github.com/pop-os/shell .; then
        echo -e "${CYAN}\nCompilando e instalando o Pop Shell localmente (não é necessário sudo)...${NC}"
        make local-install || { echo -e "${YELLOW}Falha ao compilar e instalar o Pop Shell. Verifique a saída para erros.${NC}"; }
    else
        echo -e "${YELLOW}Falha ao clonar o repositório Pop Shell! O Pop Shell não será instalado.${NC}";
    fi
    cd - > /dev/null # Volta para o diretório anterior
else
    echo -e "${YELLOW}Falha ao entrar no diretório temporário! O Pop Shell não será instalado.${NC}";
fi
echo -e "${CYAN}Removendo diretório temporário: ${TEMP_DIR}${NC}"
rm -rf "${TEMP_DIR}" || { echo -e "${YELLOW}Falha ao remover o diretório temporário: ${TEMP_DIR}. Por favor, remova-o manualmente.${NC}"; }


echo -e "${CYAN}\n--- CONFIGURANDO FLATPAK E INSTALANDO APLICATIVOS ---${NC}"
# Instala o pacote flatpak se ainda não estiver instalado
if ([ "$DISTRO" == "debian_stable" ] || [ "$DISTRO" == "debian_sid" ]) && ! command -v flatpak &> /dev/null; then
    sudo apt install -y flatpak || { echo -e "${YELLOW}Falha ao instalar o pacote flatpak no Debian. Continuando.${NC}"; }
fi

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || { echo -e "${YELLOW}Falha ao adicionar repositório Flathub. Continuando.${NC}"; }

# Aplicativos Flatpak comuns
flatpak install flathub com.github.tchx84.Flatseal -y || { echo -e "${YELLOW}Falha ao instalar Flatseal. Continuando.${NC}"; }
flatpak install flathub com.mattjakeman.ExtensionManager -y || { echo -e "${YELLOW}Falha ao instalar Extension Manager. Continuando.${NC}"; }

# Instalação do Zen Browser
if [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "debian_stable" ] || [ "$DISTRO" == "debian_sid" ]; then
    flatpak install flathub app.zen_browser.zen -y || { echo -e "${YELLOW}Falha ao instalar Zen Browser (Flatpak). Continuando.${NC}"; }
elif [ "$DISTRO" == "cachyos" ]; then
    paru -S --noconfirm zen-browser-bin || { echo -e "${YELLOW}Falha ao instalar Zen Browser (AUR) no CachyOS. Continuando.${NC}"; }
fi


### Instalação de Drivers NVIDIA (Opcional - Apenas para Fedora e Debian)

if [ "$DISTRO" == "fedora" ]; then
    read -r -p "$(echo -e "${YELLOW}Instalar drivers NVIDIA? [s/N]: ${NC}")" confirm_nvidia_drivers
    if [[ "$confirm_nvidia_drivers" =~ ^[Ss]$ ]]; then
        echo -e "${CYAN}\n--- INSTALANDO DRIVERS NVIDIA ---${NC}"
        sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda || { echo -e "${YELLOW}Falha ao instalar drivers NVIDIA no Fedora. Verifique se o RPM Fusion está configurado corretamente.${NC}"; }
    fi
elif [ "$DISTRO" == "debian_stable" ] || [ "$DISTRO" == "debian_sid" ]; then
    read -r -p "$(echo -e "${YELLOW}Instalar drivers NVIDIA? [s/N]: ${NC}")" confirm_nvidia_drivers
    if [[ "$confirm_nvidia_drivers" =~ ^[Ss]$ ]]; then
        echo -e "${CYAN}\n--- HABILITANDO NON-FREE E INSTALANDO DRIVERS NVIDIA ---${NC}"
        # Habilita a seção non-free se ainda não estiver habilitada
        if ! grep -q "non-free" /etc/apt/sources.list; then
            echo -e "${CYAN}Adicionando 'non-free' aos repositórios APT...${NC}"
            # Para Sid, as fontes devem apontar para 'unstable'
            if [ "$DISTRO" == "debian_sid" ]; then
                echo "deb http://deb.debian.org/debian/ unstable main contrib non-free" | sudo tee /etc/apt/sources.list > /dev/null
                echo "deb-src http://deb.debian.org/debian/ unstable main contrib non-free" | sudo tee -a /etc/apt/sources.list > /dev/null
            else # Debian Stable
                sudo sed -i 's/ main$/ main contrib non-free/' /etc/apt/sources.list
                sudo sed -i 's/ main non-free-firmware$/ main contrib non-free non-free-firmware/' /etc/apt/sources.list # Para Debian 12+
            fi
            sudo apt update -y || { echo -e "${YELLOW}Falha ao atualizar APT após adicionar non-free. Continuando.${NC}"; }
        fi

        sudo apt install -y nvidia-driver firmware-misc-nonfree || { echo -e "${YELLOW}Falha ao instalar drivers NVIDIA no Debian. Verifique sua placa de vídeo e repositórios.${NC}"; }
        echo -e "${YELLOW}Após a instalação dos drivers NVIDIA, é **altamente recomendado** reiniciar o sistema para que as alterações entrem em vigor.${NC}"
    fi
fi

echo -e "${GREEN}\n✅ Configuração e instalação concluídas! Reinicie o sistema.${NC}"
echo -e "${YELLOW}Lembre-se de reiniciar o sistema para aplicar todas as mudanças.${NC}"
