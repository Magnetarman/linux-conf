#!/bin/bash

# Colori per migliorare la leggibilità
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

# Funzione per messaggi
print_msg() {
    echo -e "${GREEN}==>${RESET} $1"
}

print_warn() {
    echo -e "${YELLOW}==> ATTENZIONE:${RESET} $1"
}

print_error() {
    echo -e "${RED}==> ERRORE:${RESET} $1"
}

# Funzione per verificare se un comando esiste
command_exists() {
    command -v "$1" &> /dev/null
}

# Aggiorna la lista dei mirror con gestione degli errori
print_msg "Aggiornamento della lista dei mirror..."

# Verifica se reflector è installato
if ! command_exists reflector; then
    print_warn "reflector non trovato. Installazione in corso..."
    sudo pacman -S --noconfirm reflector
    
    # Verifica se l'installazione è riuscita
    if ! command_exists reflector; then
        print_error "Impossibile installare reflector. Saltando l'aggiornamento dei mirror."
    fi
fi

# Prova ad aggiornare i mirror con reflector (se installato)
if command_exists reflector; then
    if ! sudo reflector --country 'Italy,Germany,France' --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist; then
        print_warn "Aggiornamento con reflector fallito. Tentativo con metodo alternativo..."
        
        # Backup del file mirrorlist originale
        sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
        
        # Verifica se rankmirrors è disponibile (fa parte di pacman-contrib)
        if command_exists rankmirrors; then
            print_msg "Utilizzo rankmirrors come alternativa..."
            # Ottieni i mirror dall'archivio Arch e ordinali
            curl -s "https://archlinux.org/mirrorlist/?country=IT&country=DE&country=FR&protocol=https&use_mirror_status=on" | \
            sed -e 's/^#Server/Server/' -e '/^#/d' | \
            rankmirrors -n 10 - | \
            sudo tee /etc/pacman.d/mirrorlist
        else
            print_warn "rankmirrors non disponibile. Utilizzo lista mirror predefinita..."
            
            # Crea una lista di mirror predefinita
            echo "# Mirror predefiniti" | sudo tee /etc/pacman.d/mirrorlist
            echo "Server = https://mirror.23media.com/archlinux/\$repo/os/\$arch" | sudo tee -a /etc/pacman.d/mirrorlist
            echo "Server = https://archlinux.mailtunnel.eu/\$repo/os/\$arch" | sudo tee -a /etc/pacman.d/mirrorlist
            echo "Server = https://mirrors.niyawe.de/archlinux/\$repo/os/\$arch" | sudo tee -a /etc/pacman.d/mirrorlist
            echo "Server = https://arch.yourlabs.org/\$repo/os/\$arch" | sudo tee -a /etc/pacman.d/mirrorlist
            echo "Server = https://mirror.cyberbits.eu/archlinux/\$repo/os/\$arch" | sudo tee -a /etc/pacman.d/mirrorlist
        fi
    else
        print_msg "Aggiornamento mirror completato con successo."
    fi
else
    print_warn "reflector non disponibile. Saltando l'aggiornamento dei mirror."
fi

# Aggiorna il sistema
print_msg "Aggiornando il sistema..."
sudo pacman -Syu --noconfirm

# Controlla e installa yay se necessario
if ! command_exists yay; then
    print_warn "yay non trovato. Installazione in corso..."
    sudo pacman -S --needed git base-devel --noconfirm
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
else
    print_msg "yay già installato."
fi

# ============= INSTALLAZIONE PACCHETTI CATEGORIZZATI ============= #

# ----- Pacchetti di sistema e utilità -----
print_msg "Installazione utilità di sistema..."
sudo pacman -S --noconfirm ffmpeg
yay -S --needed --noconfirm \
    p7zip \
    p7zip-gui \
    baobab \
    fastfetch-git \
    libratbag \
    hdsentinel \
    piper \
    freefilesync-bin \
    mediainfo-gui

# ----- Browser web e comunicazione -----
print_msg "Installazione browser e app di comunicazione..."
yay -S --needed --noconfirm \
    firefox \
    brave-bin \
    discord \
    zoom \
    telegram-desktop \
    whatsapp-linux-desktop \
    thunderbird \
    localsend-bin \
    google-chrome \
    microsoft-edge-stable \

# ----- Multimedia e intrattenimento -----
print_msg "Installazione applicazioni multimediali..."
yay -S --needed --noconfirm \
    vlc \
    handbrake \
    mkvtoolnix-gui \
    freac \
    mp3tag \
    obs-studio \
    youtube-to-mp3 \
    spotify \
    plexamp-appimage \
    reaper \

# ----- Download e condivisione file -----
print_msg "Installazione app per download e condivisione file..."
yay -S --needed --noconfirm \
    qbittorrent \
    jdownloader2 \
    winscp \
    rustdesk-bin

# ----- Giochi e piattaforme gaming -----
print_msg "Installazione piattaforme di gaming..."
yay -S --needed --noconfirm \
    steam \
    heroic-games-launcher-bin \
    legendary

# ----- Produttività e strumenti di lavoro -----
print_msg "Installazione strumenti di produttività..."
sudo pacman -S --noconfirm python-pip tk
yay -S --needed --noconfirm \
    obsidian \
    visual-studio-code-bin \
    github-desktop-bin \
    onlyoffice-bin \
    jdk-openjdk \
    enpass-bin \
    simple-scan

# ----- Grafica e design -----
print_msg "Installazione software per grafica..."
yay -S --needed --noconfirm \
    upscayl-bin \
    occt

# ----- AI e machine learning -----
print_msg "Installazione di chatbox (GUI per Ollama)..."
yay -S --needed --noconfirm \
    chatbox-ce-bin

# ----- Software di compatibilità -----
print_msg "Installazione strumenti di compatibilità..."
yay -S --needed --noconfirm \
    wine

# =============  Installazione fancontrol-gui  ============= #
print_msg "Installazione fancontrol-gui..."

# Scarica il PKGBUILD
print_msg "Scaricando il PKGBUILD di fancontrol-gui..."
yay -G fancontrol-gui
if [ $? -ne 0 ]; then
    print_error "Impossibile scaricare il PKGBUILD. Uscita."
    exit 1
fi

# Entra nella directory
cd fancontrol-gui
if [ $? -ne 0 ]; then
    print_error "Impossibile entrare nella directory fancontrol-gui. Uscita."
    exit 1
fi

# Modifica il PKGBUILD
print_msg "Modificando il PKGBUILD per forzare la versione minima di CMake..."
sed -i 's/cmake /cmake -DCMAKE_POLICY_VERSION_MINIMUM=3.5 /' PKGBUILD
if [ $? -ne 0 ]; then
    print_error "Impossibile modificare il PKGBUILD. Uscita."
    exit 1
fi

# Compila e installa il pacchetto
print_msg "Compilando e installando fancontrol-gui..."
makepkg -si --noconfirm
if [ $? -ne 0 ]; then
    print_error "Compilazione o installazione fallita. Controlla l'output di makepkg."
    exit 1
fi

# Pulisci (opzionale)
print_msg "Pulizia..."
cd ..
rm -rf fancontrol-gui

print_msg "fancontrol-gui installato con successo!"

# ============= Installazione Ollama ============= #
echo "Scarico lo script di installazione di Ollama..."
curl -fsSL https://ollama.com/install.sh -o install_ollama.sh

echo "Eseguo lo script..."
bash install_ollama.sh

# Funzione per stampare con colore
print_msg() {
    echo -e "\033[1;32m$1\033[0m"
}

# Lista dei modelli disponibili
MODELS=("llama3" "mistral" "gemma" "codellama" "llava" "phi")

# Controllo se ollama è già installato
if ! command -v ollama &> /dev/null; then
    print_msg "Ollama non è installato. Procedo con l'installazione..."
    if command -v yay &> /dev/null; then
        yay -S ollama-bin --noconfirm
    elif command -v paru &> /dev/null; then
        paru -S ollama-bin --noconfirm
    else
        echo "Errore: è richiesto yay o paru per installare ollama da AUR."
        exit 1
    fi
else
    print_msg "Ollama è già installato."
fi

# Prompt di selezione modello
echo "Scegli un modello da installare:"
select MODEL in "${MODELS[@]}"; do
    if [[ -n "$MODEL" ]]; then
        print_msg "Hai selezionato il modello: $MODEL"
        break
    else
        echo "Selezione non valida."
    fi
done

# Avvio del servizio ollama
print_msg "Avvio del servizio ollama..."
sudo systemctl enable --now ollama.service

# Verifica se il servizio è attivo
if systemctl is-active --quiet ollama; then
    print_msg "Servizio ollama attivo."

    # Verifica se il modello è già installato
    if ollama list | grep -q "^$MODEL[[:space:]]"; then
        print_msg "Il modello '$MODEL' è già installato. Salto il download."
    else
        print_msg "Scarico il modello '$MODEL'..."
        ollama pull "$MODEL"
    fi
else
    echo "Errore nell'avvio del servizio ollama."
    exit 1
fi


# ============= INSTALLAZIONE MYBASH ============= #
print_msg "Installazione di MyBash (shell personalizzata)..."

# Definisci il tool di escalation (sudo è già disponibile in questo script)
ESCALATION_TOOL="sudo"
PACKAGER="pacman"

# Directory di destinazione per mybash
gitpath="$HOME/.local/share/mybash"

# Installazione delle dipendenze per mybash
print_msg "Installazione delle dipendenze per MyBash..."
if [ ! -f "/usr/share/bash-completion/bash_completion" ] || ! command_exists bash tar bat tree unzip fc-list git; then
    print_warn "Installazione di bash e le sue dipendenze..."
    $ESCALATION_TOOL $PACKAGER -S --needed --noconfirm bash bash-completion tar bat tree unzip fontconfig git
fi

# Clonazione del repository mybash
print_msg "Clonazione del repository MyBash..."
if [ -d "$gitpath" ]; then
    print_warn "Directory MyBash esistente. Rimozione in corso..."
    rm -rf "$gitpath"
fi
mkdir -p "$HOME/.local/share"
cd "$HOME" && git clone https://github.com/ChrisTitusTech/mybash.git "$gitpath"

# Installazione del font Nerd Font
print_msg "Verifica e installazione del font MesloLGS Nerd Font..."
FONT_NAME="MesloLGS Nerd Font Mono"
if fc-list :family | grep -iq "$FONT_NAME"; then
    print_msg "Font '$FONT_NAME' già installato."
else
    print_warn "Installazione del font '$FONT_NAME'..."
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
    FONT_DIR="$HOME/.local/share/fonts"
    TEMP_DIR=$(mktemp -d)
    curl -sSLo "$TEMP_DIR/${FONT_NAME}.zip" "$FONT_URL"
    unzip "$TEMP_DIR/${FONT_NAME}.zip" -d "$TEMP_DIR"
    mkdir -p "$FONT_DIR/$FONT_NAME"
    mv "${TEMP_DIR}"/*.ttf "$FONT_DIR/$FONT_NAME"
    fc-cache -fv
    rm -rf "${TEMP_DIR}"
    print_msg "Font '$FONT_NAME' installato con successo."
fi

# Installazione di Starship e FZF
print_msg "Installazione di Starship (prompt personalizzato)..."
if command_exists starship; then
    print_msg "Starship già installato."
else
    if ! curl -sSL https://starship.rs/install.sh | $ESCALATION_TOOL sh; then
        print_error "Si è verificato un errore durante l'installazione di Starship!"
        exit 1
    fi
fi

print_msg "Installazione di FZF (ricerca fuzzy)..."
if command_exists fzf; then
    print_msg "FZF già installato."
else
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    $ESCALATION_TOOL ~/.fzf/install
fi

# Installazione di Zoxide
print_msg "Installazione di Zoxide (navigazione intelligente tra directory)..."
if command_exists zoxide; then
    print_msg "Zoxide già installato."
else
    if ! curl -sSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
        print_error "Si è verificato un errore durante l'installazione di Zoxide!"
        exit 1
    fi
fi

# Collegamento dei file di configurazione
print_msg "Collegamento dei file di configurazione..."
OLD_BASHRC="$HOME/.bashrc"
if [ -e "$OLD_BASHRC" ] && [ ! -e "$HOME/.bashrc.bak" ]; then
    print_warn "Spostamento del vecchio file di configurazione bash in $HOME/.bashrc.bak"
    if ! mv "$OLD_BASHRC" "$HOME/.bashrc.bak"; then
        print_error "Impossibile spostare il vecchio file di configurazione bash!"
        exit 1
    fi
fi

print_warn "Collegamento del nuovo file di configurazione bash..."
ln -svf "$gitpath/.bashrc" "$HOME/.bashrc" || {
    print_error "Impossibile creare il link simbolico per .bashrc"
    exit 1
}

# Assicurati che la directory di configurazione esista
mkdir -p "$HOME/.config"

ln -svf "$gitpath/starship.toml" "$HOME/.config/starship.toml" || {
    print_error "Impossibile creare il link simbolico per starship.toml"
    exit 1
}

print_msg "MyBash installato con successo! Riavvia la shell per vedere i cambiamenti."

# ============= INSTALLAZIONE AUTO-CPUFREQ ============= #
print_msg "Installazione e configurazione di auto-cpufreq..."

installAutoCpufreq() {
    print_msg "Installazione di auto-cpufreq..."
    
    if ! command_exists auto-cpufreq; then
        print_warn "auto-cpufreq non trovato. Installazione in corso..."
        
        # Verifica se powerprofilesctl è attivo e lo disabilita
        if command_exists powerprofilesctl; then
            print_warn "Disabilitazione del servizio powerprofilesctl..."
            sudo systemctl disable --now power-profiles-daemon
        fi
        
        # Installazione tramite AUR
        yay -S --needed --noconfirm auto-cpufreq
        sudo systemctl enable --now auto-cpufreq
    else
        print_msg "auto-cpufreq è già installato."
    fi
}

configureAutoCpufreq() {
    print_msg "Configurazione di auto-cpufreq in base al tipo di dispositivo..."
    
    if command_exists auto-cpufreq; then
        # Verifica se il sistema è un laptop o un desktop controllando la presenza di batterie
        if ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then
            print_msg "Sistema rilevato come laptop. Configurazione in modalità powersave..."
            sudo auto-cpufreq --force powersave
        else
            print_msg "Sistema rilevato come desktop. Configurazione in modalità performance..."
            sudo auto-cpufreq --force performance
        fi
        print_msg "auto-cpufreq configurato con successo!"
    else
        print_error "auto-cpufreq non è installato. Installazione fallita."
    fi
}

# Esegui l'installazione e la configurazione di auto-cpufreq
installAutoCpufreq
configureAutoCpufreq

# ============= INSTALLAZIONE BOTTLES ============= #
print_msg "Installazione e configurazione di BOTTLES..."
# Ottiene la directory in cui si trova questo script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Controlla se common-script.sh esiste nella stessa directory
if [ ! -f "$SCRIPT_DIR/common-script.sh" ]; then
    echo "common-script.sh non trovato in $SCRIPT_DIR"
    exit 1
fi

# Include common-script.sh dalla stessa directory
. "$SCRIPT_DIR/common-script.sh"

installBottles() {
    if ! command_exists com.usebottles.bottles; then
        printf "%b\n" "${YELLOW}Installing Bottles...${RC}"
        flatpak install -y flathub com.usebottles.bottles
    else
        printf "%b\n" "${GREEN}Bottles is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkFlatpak
installBottles

# ============= SETUP FAST FETCH ============= #
print_msg "Configurazione di Fast Fetch..."

# Ottiene la directory in cui si trova questo script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Controlla se common-script.sh esiste nella stessa directory
if [ ! -f "$SCRIPT_DIR/common-script.sh" ]; then
    echo "common-script.sh non trovato in $SCRIPT_DIR"
    exit 1
fi

# Include common-script.sh dalla stessa directory
. "$SCRIPT_DIR/common-script.sh"

installFastfetch() {
    if ! command_exists fastfetch; then
        printf "%b\n" "${YELLOW}Installing Fastfetch...${RC}"
        case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm fastfetch
            ;;
        apt-get | nala)
            curl -sSLo /tmp/fastfetch.deb https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.deb
            "$ESCALATION_TOOL" "$PACKAGER" install -y /tmp/fastfetch.deb
            rm /tmp/fastfetch.deb
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add fastfetch
            ;;
        *)
            "$ESCALATION_TOOL" "$PACKAGER" install -y fastfetch
            ;;
        esac
    else
        printf "%b\n" "${GREEN}Fastfetch is already installed.${RC}"
    fi
}

setupFastfetchConfig() {
    printf "%b\n" "${YELLOW}Copying Fastfetch config files...${RC}"
    if [ -d "${HOME}/.config/fastfetch" ] && [ ! -d "${HOME}/.config/fastfetch-bak" ]; then
        cp -r "${HOME}/.config/fastfetch" "${HOME}/.config/fastfetch-bak"
    fi
    mkdir -p "${HOME}/.config/fastfetch/"
    curl -sSLo "${HOME}/.config/fastfetch/config.jsonc" https://raw.githubusercontent.com/ChrisTitusTech/mybash/main/config.jsonc
}

setupFastfetchShell() {
    printf "%b\n" "${YELLOW}Configuring shell integration...${RC}"

    current_shell=$(basename "$SHELL")
    rc_file=""

    case "$current_shell" in
    "bash")
        rc_file="$HOME/.bashrc"
        ;;
    "zsh")
        rc_file="$HOME/.zshrc"
        ;;
    "fish")
        rc_file="$HOME/.config/fish/config.fish"
        ;;
    "nu")
        rc_file="$HOME/.config/nushell/config.nu"
        ;;
    *)
        printf "%b\n" "${RED}$current_shell is not supported. Update your shell configuration manually.${RC}"
        ;;
    esac

    if [ ! -f "$rc_file" ]; then
        printf "%b\n" "${RED}Shell config file $rc_file not found${RC}"
    else
        if grep -q "fastfetch" "$rc_file"; then
            printf "%b\n" "${YELLOW}Fastfetch is already configured in $rc_file${RC}"
            return 0
        else
            printf "%b" "${GREEN}Would you like to add fastfetch to $rc_file? [y/N] ${RC}"
            read -r response
            if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
                printf "\n# Run fastfetch on shell initialization\nfastfetch\n" >>"$rc_file"
                printf "%b\n" "${GREEN}Added fastfetch to $rc_file${RC}"
            else
                printf "%b\n" "${YELLOW}Skipped adding fastfetch to shell config${RC}"
            fi
        fi
    fi

}

checkEnv
checkEscalationTool
installFastfetch
setupFastfetchConfig
setupFastfetchShell

# ============= SETUP LIBRERIE ADDIZIONALI PER IL GAMING ============= #
print_msg "Installazione addizionale librerie Gaming..."

# Ottiene la directory in cui si trova questo script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Controlla se common-script.sh esiste nella stessa directory
if [ ! -f "$SCRIPT_DIR/common-script.sh" ]; then
    echo "common-script.sh non trovato in $SCRIPT_DIR"
    exit 1
fi

# Include common-script.sh dalla stessa directory
. "$SCRIPT_DIR/common-script.sh"

installDepend() {
    DEPENDENCIES='wine dbus git'
    printf "%b\n" "${YELLOW}Installing dependencies...${RC}"
    case "$PACKAGER" in
        pacman)
            #Check for multilib
            if ! grep -q "^\s*\[multilib\]" /etc/pacman.conf; then
                echo "[multilib]" | "$ESCALATION_TOOL" tee -a /etc/pacman.conf
                echo "Include = /etc/pacman.d/mirrorlist" | "$ESCALATION_TOOL" tee -a /etc/pacman.conf
                "$ESCALATION_TOOL" "$PACKAGER" -Syu
            else
                printf "%b\n" "${GREEN}Multilib is already enabled.${RC}"
            fi

            DISTRO_DEPS="gnutls lib32-gnutls base-devel gtk2 gtk3 lib32-gtk2 lib32-gtk3 libpulse lib32-libpulse alsa-lib lib32-alsa-lib \
                alsa-utils alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib giflib lib32-giflib libpng lib32-libpng \
                libldap lib32-libldap openal lib32-openal libxcomposite lib32-libxcomposite libxinerama lib32-libxinerama \
                ncurses lib32-ncurses vulkan-icd-loader lib32-vulkan-icd-loader ocl-icd lib32-ocl-icd libva lib32-libva \
                gst-plugins-base-libs lib32-gst-plugins-base-libs sdl2 lib32-sdl2 v4l-utils lib32-v4l-utils sqlite lib32-sqlite"

            $AUR_HELPER -S --needed --noconfirm $DEPENDENCIES $DISTRO_DEPS
            ;;
        apt-get | nala)
            DISTRO_DEPS="libasound2-plugins:i386 libsdl2-2.0-0:i386 libdbus-1-3:i386 libsqlite3-0:i386 wine64 wine32"

            "$ESCALATION_TOOL" dpkg --add-architecture i386

            if [ "$DTYPE" != "pop" ]; then
                "$ESCALATION_TOOL" "$PACKAGER" install -y software-properties-common
                "$ESCALATION_TOOL" apt-add-repository contrib -y
            fi

            "$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" "$PACKAGER" install -y $DEPENDENCIES $DISTRO_DEPS
            ;;
        dnf)
            if [ "$(rpm -E %fedora)" -le 41 ]; then
                "$ESCALATION_TOOL" "$PACKAGER" install ffmpeg ffmpeg-libs -y
                "$ESCALATION_TOOL" "$PACKAGER" install -y $DEPENDENCIES
            else
                printf "%b\n" "${CYAN}Fedora < 41 detected. Installing rpmfusion repos.${RC}"
                "$ESCALATION_TOOL" "$PACKAGER" install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm -y
                "$ESCALATION_TOOL" "$PACKAGER" config-manager --enable fedora-cisco-openh264 -y
                "$ESCALATION_TOOL" "$PACKAGER" install -y $DEPENDENCIES
            fi
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" -n install $DEPENDENCIES
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager ${PACKAGER}${RC}"
            exit 1
            ;;
    esac
}

installAdditionalDepend() {
    case "$PACKAGER" in
        pacman)
            DISTRO_DEPS='steam lutris goverlay'
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm $DISTRO_DEPS
            ;;
        apt-get | nala)
            version=$(git -c 'versionsort.suffix=-' ls-remote --tags --sort='v:refname' https://github.com/lutris/lutris |
                grep -v 'beta' |
                tail -n1 |
                cut -d '/' --fields=3)

            version_no_v=$(echo "$version" | tr -d v)
            curl -sSLo "lutris_${version_no_v}_all.deb" "https://github.com/lutris/lutris/releases/download/${version}/lutris_${version_no_v}_all.deb"

            printf "%b\n" "${YELLOW}Installing Lutris...${RC}"
            "$ESCALATION_TOOL" "$PACKAGER" install -y ./lutris_"${version_no_v}"_all.deb

            rm lutris_"${version_no_v}"_all.deb

            printf "%b\n" "${GREEN}Lutris Installation complete.${RC}"
            printf "%b\n" "${YELLOW}Installing steam...${RC}"

            if lsb_release -i | grep -qi Debian; then
                "$ESCALATION_TOOL" apt-add-repository non-free -y
                "$ESCALATION_TOOL" "$PACKAGER" install steam-installer -y
            else
                "$ESCALATION_TOOL" "$PACKAGER" install -y steam
            fi
            ;;
        dnf)
            DISTRO_DEPS='steam lutris'
            "$ESCALATION_TOOL" "$PACKAGER" install -y $DISTRO_DEPS
            ;;
        zypper)
            DISTRO_DEPS='lutris'
            "$ESCALATION_TOOL" "$PACKAGER" -n install $DISTRO_DEPS
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager ${PACKAGER}${RC}"
            exit 1
            ;;
    esac
}

checkEnv
checkAURHelper
checkEscalationTool
installDepend
installAdditionalDepend


# ============= APPLICAZIONE TEMI ADDIZIONALI ============= #
print_msg "Applicazione Temi Addizionali..."

# Ottiene la directory in cui si trova questo script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Controlla se common-script.sh esiste nella stessa directory
if [ ! -f "$SCRIPT_DIR/common-script.sh" ]; then
    echo "common-script.sh non trovato in $SCRIPT_DIR"
    exit 1
fi

# Include common-script.sh dalla stessa directory
. "$SCRIPT_DIR/common-script.sh"

install_theme_tools() {
    printf "%b\n" "${YELLOW}Installing theme tools (qt6ct and kvantum)...${RC}"
    case "$PACKAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" install -y qt6ct kvantum
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install qt6ct kvantum
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install -y qt6ct kvantum
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm qt6ct kvantum
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            exit 1
            ;;
    esac
}

applyTheming() {
    printf "%b\n" "${YELLOW}Applying global theming...${RC}"
    case "$XDG_CURRENT_DESKTOP" in
        KDE)
            lookandfeeltool -a org.kde.breezedark.desktop
            successOutput
            exit 0
            ;;
        GNOME)
            gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
            gsettings set org.gnome.desktop.interface icon-theme "Adwaita"
            successOutput
            exit 0
            ;;
        *)
            return
            ;;
    esac
}

configure_qt6ct() {
    printf "%b\n" "${YELLOW}Configuring qt6ct...${RC}"
    mkdir -p "$HOME/.config/qt6ct"
    cat <<EOF > "$HOME/.config/qt6ct/qt6ct.conf"
[Appearance]
style=kvantum
color_scheme=default
icon_theme=breeze
EOF
    printf "%b\n" "${GREEN}qt6ct configured successfully.${RC}"

    # Add QT_QPA_PLATFORMTHEME to /etc/environment
    if ! grep -q "QT_QPA_PLATFORMTHEME=qt6ct" /etc/environment; then
        printf "%b\n" "${YELLOW}Adding QT_QPA_PLATFORMTHEME to /etc/environment...${RC}"
        echo "QT_QPA_PLATFORMTHEME=qt6ct" | "$ESCALATION_TOOL" tee -a /etc/environment > /dev/null
        printf "%b\n" "${GREEN}QT_QPA_PLATFORMTHEME added to /etc/environment.${RC}"
    else
        printf "%b\n" "${GREEN}QT_QPA_PLATFORMTHEME already set in /etc/environment.${RC}"
    fi
}

configure_kvantum() {
    printf "%b\n" "${YELLOW}Configuring Kvantum...${RC}"
    mkdir -p "$HOME/.config/Kvantum"
    cat <<EOF > "$HOME/.config/Kvantum/kvantum.kvconfig"
[General]
theme=KvArcDark
EOF
    printf "%b\n" "${GREEN}Kvantum configured successfully.${RC}"
}

successOutput() {
    printf "%b\n" "${GREEN}Global theming applied successfully.${RC}"
}

checkEnv
checkEscalationTool
applyTheming
install_theme_tools
configure_qt6ct
configure_kvantum
successOutput

# ============= INSTALLAZIONE FONT ADDIZIONALI ============= #
print_msg "Installazione Font Addizionali (orphans)..."

# Ottiene la directory in cui si trova questo script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Controlla se common-script.sh esiste nella stessa directory
if [ ! -f "$SCRIPT_DIR/common-script.sh" ]; then
    echo "common-script.sh non trovato in $SCRIPT_DIR"
    exit 1
fi

# Include common-script.sh dalla stessa directory
. "$SCRIPT_DIR/common-script.sh"


InstallTermiusFonts() {
    if [ ! -f "/usr/share/kbd/consolefonts/ter-c18b.psf.gz" ] && 
       [ ! -f "/usr/share/consolefonts/Uni3-TerminusBold18x10.psf.gz" ] && 
       [ ! -f "/usr/lib/kbd/consolefonts/ter-p32n.psf.gz" ]; then
    printf "%b\n" "${YELLOW}Installing Terminus Fonts...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm terminus-font
                ;;
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y fonts-terminus
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y terminus-fonts-console
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Terminus Fonts is already installed.${RC}"
    fi
}

SetTermiusFonts() {
        case "$DTYPE" in
            arch)
                printf "%b\n" "${YELLOW}Updating FONT= line in /etc/vconsole.conf...${RC}"
                "$ESCALATION_TOOL" sed -i 's/^FONT=.*/FONT=ter-v32b/' /etc/vconsole.conf
                if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
                   "$ESCALATION_TOOL" setfont -C /dev/tty1 ter-v32b
                fi
                printf "%b\n" "${GREEN}Terminus font set for TTY.${RC}"
                ;;
            debian)
                
                printf "%b\n" "${YELLOW}Updating console-setup configuration...${RC}"
                "$ESCALATION_TOOL" sed -i 's/^CODESET=.*/CODESET="guess"/' /etc/default/console-setup
                "$ESCALATION_TOOL" sed -i 's/^FONTFACE=.*/FONTFACE="TerminusBold"/' /etc/default/console-setup
                "$ESCALATION_TOOL" sed -i 's/^FONTSIZE=.*/FONTSIZE="16x32"/' /etc/default/console-setup
                printf "%b\n" "${GREEN}Console-setup configuration updated for Terminus font.${RC}"
                # Editing console-setup requires initramfs to be regenerated
                "$ESCALATION_TOOL" update-initramfs -u
                if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then                    
                   "$ESCALATION_TOOL" setfont -C /dev/tty1 /usr/share/consolefonts/Uni3-TerminusBold32x16.psf.gz
                fi
                printf "%b\n" "${GREEN}Terminus font has been set for TTY.${RC}"
                ;;
            fedora)
                printf "%b\n" "${YELLOW}Updating FONT= line in /etc/vconsole.conf...${RC}"
                "$ESCALATION_TOOL" sed -i 's/^FONT=.*/FONT=ter-v32b/' /etc/vconsole.conf
                if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then 
                  "$ESCALATION_TOOL" setfont -C /dev/tty1 ter-v32b
                fi               
                printf "%b\n" "${GREEN}Terminus font has been set for TTY.${RC}"
                ;;
        esac
}

checkEnv
InstallTermiusFonts
SetTermiusFonts

# =============  Installazione Responsively App Tramite APP IMAGE  ============= #
print_msg "Installazione Responsiveli App Tramite APP IMAGE..."
# Variabili
APP_NAME="ResponsivelyApp"
VERSION="1.16.0"
APPIMAGE_NAME="$APP_NAME-$VERSION.AppImage"
DOWNLOAD_URL="https://github.com/responsively-org/responsively-app-releases/releases/download/v$VERSION/$APPIMAGE_NAME"
INSTALL_DIR="$HOME/.local/bin"
DESKTOP_FILE="$HOME/.local/share/applications/${APP_NAME}.desktop"

# Crea cartelle se non esistono
mkdir -p "$INSTALL_DIR"
mkdir -p "$(dirname "$DESKTOP_FILE")"

# Scarica l'AppImage solo se non esiste già
if [ ! -f "$INSTALL_DIR/$APPIMAGE_NAME" ]; then
    echo "Scaricando $APPIMAGE_NAME..."
    curl -L "$DOWNLOAD_URL" -o "$INSTALL_DIR/$APPIMAGE_NAME"
    chmod +x "$INSTALL_DIR/$APPIMAGE_NAME"
else
    echo "L'AppImage è già presente in $INSTALL_DIR"
fi

# Crea file .desktop
echo "Creando file .desktop..."
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Responsively App
Exec=$INSTALL_DIR/$APPIMAGE_NAME
Icon=web-browser
Type=Application
Categories=Development;WebDevelopment;
Terminal=false
EOF

# Aggiorna database delle applicazioni
update-desktop-database "$HOME/.local/share/applications/" >/dev/null 2>&1


# =============  Installazione Da Vinci Resolve  ============= #
print_msg "Installazione Da Vinci Resolve (Metodo Alternativo)..."
# URL del file DaVinci Resolve
URL="https://swr.cloud.blackmagicdesign.com/DaVinciResolve/v19.1.4/DaVinci_Resolve_19.1.4_Linux.zip?verify=1746015631-pVwva6btO%2FbqLQknJJtJj7WZZfFgv3cNf3vp2qbSDXM%3D"
FILENAME="DaVinci_Resolve_19.1.4_Linux.zip"

# Cartella di destinazione
DEST_DIR="$HOME/Downloads/DaVinci_Resolve"

# Crea la cartella di destinazione se non esiste
mkdir -p "$DEST_DIR"

# Naviga nella cartella di destinazione
cd "$DEST_DIR" || exit 1

# Scarica il file zip di DaVinci Resolve
echo "Scaricando DaVinci Resolve..."
wget -O "$FILENAME" "$URL"

# Controlla se il download è stato completato
if [ ! -f "$FILENAME" ]; then
    echo "Errore nel download. Controlla il link."
    exit 1
fi

echo "Download completato!"

# Estrai il file zip
echo "Estraendo il file..."
unzip "$FILENAME"

# Controlla se il file .run è presente
if [ ! -f "DaVinci_Resolve_19.1.4_Linux.run" ]; then
    echo "Errore: il file .run non è stato estratto correttamente."
    exit 1
fi

# Rendi eseguibile il file .run
echo "Rendendo eseguibile il file di installazione..."
chmod +x DaVinci_Resolve_19.1.4_Linux.run

# Esegui l'installazione
echo "Avviando l'installazione di DaVinci Resolve..."
sudo ./DaVinci_Resolve_19.1.4_Linux.run

echo "Installazione completata!"



# =============  Installazione MH Audio Converter con Wine  ============= #
print_msg "Installazione MH Audio Converter con Wine..."

# Definizione delle variabili
DOWNLOAD_URL="https://www.mediahuman.com/download/MHAudioConverter-x64.exe"
DOWNLOAD_PATH="/tmp/MHAudioConverter-x64.exe"
WINE_PREFIX="$HOME/.wine_mhaudioconverter"

# Creazione della directory per il prefisso Wine (se non esiste)
if [ ! -d "$WINE_PREFIX" ]; then
    print_msg "Creazione di un nuovo prefisso Wine in $WINE_PREFIX..."
    mkdir -p "$WINE_PREFIX"
fi

# Download del file
print_msg "Download di MH Audio Converter..."
if command_exists wget; then
    wget -O "$DOWNLOAD_PATH" "$DOWNLOAD_URL"
elif command_exists curl; then
    curl -L "$DOWNLOAD_URL" -o "$DOWNLOAD_PATH"
else
    print_warn "È necessario installare wget o curl per scaricare MH Audio Converter."
    # Prova ad installare wget
    sudo pacman -S --noconfirm wget
    if command_exists wget; then
        wget -O "$DOWNLOAD_PATH" "$DOWNLOAD_URL"
    else
        print_error "Impossibile installare wget o curl."
    fi
fi

# Controllo se il download è andato a buon fine
if [ ! -f "$DOWNLOAD_PATH" ]; then
    print_warn "Download di MH Audio Converter fallito. Verificare la connessione internet."
else
    # Esecuzione dell'installer con Wine
    print_msg "Installazione di MH Audio Converter con Wine..."
    WINEPREFIX="$WINE_PREFIX" wine "$DOWNLOAD_PATH"

    # Controllo del risultato dell'installazione
    if [ $? -eq 0 ]; then
        print_msg "Installazione di MH Audio Converter completata con successo!"
        print_msg "Per avviare MH Audio Converter, usa: WINEPREFIX=\"$WINE_PREFIX\" wine \"$WINE_PREFIX/drive_c/Program Files/MediaHuman/Audio Converter/MHAudioConverter.exe\""
        
        # Crea un lanciatore desktop
        DESKTOP_DIR="$HOME/.local/share/applications"
        mkdir -p "$DESKTOP_DIR"
        
        cat > "$DESKTOP_DIR/mhaudioconverter.desktop" << EOF
[Desktop Entry]
Name=MH Audio Converter
Comment=MediaHuman Audio Converter
Exec=env WINEPREFIX="$WINE_PREFIX" wine "$WINE_PREFIX/drive_c/Program Files/MediaHuman/Audio Converter/MHAudioConverter.exe"
Icon=$WINE_PREFIX/drive_c/Program\ Files/MediaHuman/Audio\ Converter/MHAudioConverter.exe
Type=Application
Categories=AudioVideo;Audio;
EOF
        
        print_msg "Lanciatore desktop creato per MH Audio Converter."
    else
        print_warn "Si è verificato un errore durante l'installazione di MH Audio Converter."
    fi

    # Pulizia
    print_msg "Pulizia dei file temporanei di MH Audio Converter..."
    rm -f "$DOWNLOAD_PATH"
fi

# ============= PULIZIA DEL SISTEMA ============= #

# Pulizia pacchetti orfani
print_msg "Pulizia pacchetti inutilizzati (orphans)..."
ORPHANS=$(pacman -Qtdq)
if [ -n "$ORPHANS" ]; then
    sudo pacman -Rns --noconfirm $ORPHANS
else
    echo "Nessun pacchetto orfano da rimuovere."
fi


# Pulizia cache pacman
print_msg "Pulizia cache pacman..."
sudo pacman -Sc --noconfirm

# Pulizia cache yay
print_msg "Pulizia cache yay..."
if command_exists yay; then
    yay -Sc --noconfirm
fi

# Pulizia file temporanei
print_msg "Pulizia dei file temporanei..."
sudo rm -rf /var/tmp/*
sudo journalctl --vacuum-time=7d

print_msg "Aggiornamento e pulizia completati!"
echo -e "${BLUE}Sistema Pronto !!!${RESET}"

# Chiedi se riavviare il sistema
read -rp "Vuoi riavviare il sistema? (y/n): " REBOOT_CHOICE
if [[ "$REBOOT_CHOICE" =~ ^[Yy]$ ]]; then
    echo "Riavvio in 10 secondi. Premi Ctrl+C per annullare."
    for i in {10..1}; do
        echo -ne "$i...\r"
        sleep 1
    done
    echo "Riavvio in corso..."
    sudo reboot
else
    echo "Riavvio annullato."
fi
