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
    freefilesync-bin

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
    microsoft-edge-stable

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
    reaper

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

# ============= CALCOLO DELLA DIRECTORY DELLO SCRIPT PRINCIPALE =============
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============= FUNZIONI DI SUPPORTO =============
# ============= ESECUZIONE SCRIPT ESTERNI =============
echo "==============================================="
echo "AVVIO SCRIPT ESTERNI"
echo "==============================================="
echo ""

# Script da eseguire
echo "Tentativo di esecuzione di bottles-setup.sh..."
if [ -f "bottles-setup.sh" ]; then
    echo "File bottles-setup.sh trovato. Esecuzione..."
    chmod +x bottles-setup.sh
    AUTOMATED=1 bash bottles-setup.sh
    echo "Esecuzione di bottles-setup.sh completata."
else
    echo "File bottles-setup.sh non trovato nella directory corrente."
fi
echo ""

echo "Tentativo di esecuzione di fastfetch-setup.sh..."
if [ -f "fastfetch-setup.sh" ]; then
    echo "File fastfetch-setup.sh trovato. Esecuzione..."
    chmod +x fastfetch-setup.sh
    AUTOMATED=1 bash fastfetch-setup.sh
    echo "Esecuzione di fastfetch-setup.sh completata."
else
    echo "File fastfetch-setup.sh non trovato nella directory corrente."
fi
echo ""

echo "Tentativo di esecuzione di gaming-setup.sh..."
if [ -f "gaming-setup.sh" ]; then
    echo "File gaming-setup.sh trovato. Esecuzione..."
    chmod +x gaming-setup.sh
    AUTOMATED=1 bash gaming-setup.sh
    echo "Esecuzione di gaming-setup.sh completata."
else
    echo "File gaming-setup.sh non trovato nella directory corrente."
fi
echo ""

echo "Tentativo di esecuzione di global-theme.sh..."
if [ -f "global-theme.sh" ]; then
    echo "File global-theme.sh trovato. Esecuzione..."
    chmod +x global-theme.sh
    AUTOMATED=1 bash global-theme.sh
    echo "Esecuzione di global-theme.sh completata."
else
    echo "File global-theme.sh non trovato nella directory corrente."
fi
echo ""

echo "Tentativo di esecuzione di terminus-tty.sh..."
if [ -f "terminus-tty.sh" ]; then
    echo "File terminus-tty.sh trovato. Esecuzione..."
    chmod +x terminus-tty.sh
    AUTOMATED=1 bash terminus-tty.sh
    echo "Esecuzione di terminus-tty.sh completata."
else
    echo "File terminus-tty.sh non trovato nella directory corrente."
fi
echo ""

echo "==============================================="
echo "ESECUZIONE SCRIPT ESTERNI COMPLETATA"
echo "==============================================="

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
