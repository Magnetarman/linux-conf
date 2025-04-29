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

# Aggiorna la lista dei mirror con gestione degli errori
print_msg "Aggiornamento della lista dei mirror..."

# Verifica se reflector è installato
if ! command -v reflector &> /dev/null; then
    print_warn "reflector non trovato. Installazione in corso..."
    sudo pacman -S --noconfirm reflector
    
    # Verifica se l'installazione è riuscita
    if ! command -v reflector &> /dev/null; then
        print_error "Impossibile installare reflector. Saltando l'aggiornamento dei mirror."
    fi
fi

# Prova ad aggiornare i mirror con reflector (se installato)
if command -v reflector &> /dev/null; then
    if ! sudo reflector --country 'Italy,Germany,France' --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist; then
        print_warn "Aggiornamento con reflector fallito. Tentativo con metodo alternativo..."
        
        # Backup del file mirrorlist originale
        sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
        
        # Verifica se rankmirrors è disponibile (fa parte di pacman-contrib)
        if command -v rankmirrors &> /dev/null; then
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
if ! command -v yay &> /dev/null; then
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
    fancontrol-gui \
    piper \
    freefilesync-bin

# ----- Browser web e comunicazione -----
print_msg "Installazione browser e app di comunicazione..."
yay -S --needed --noconfirm \
    firefox \
    brave-bin \
    discord \
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
    skanpage

# ----- Grafica e design -----
print_msg "Installazione software per grafica..."
yay -S --needed --noconfirm \
    upscayl-bin \
    occt

# ----- AI e machine learning -----
print_msg "Installazione di Ollama..."
yay -S --needed --noconfirm \
    ollama-bin

# ----- Software di compatibilità -----
print_msg "Installazione strumenti di compatibilità..."
yay -S --needed --noconfirm \
    wine

# ----- Installazione specifica Plexamp -----
print_msg "Configurazione Plexamp..."
print_msg "Scaricando l'ultima versione di Plexamp AppImage..."
# Aggiungi controllo per jq
if ! command -v jq &> /dev/null; then
    print_warn "jq non trovato. Installazione in corso..."
    sudo pacman -S --noconfirm jq
fi

if command -v jq &> /dev/null; then
    LATEST_URL=$(curl -s https://api.github.com/repos/plexinc/plexamp/releases/latest | jq -r .assets[0].browser_download_url)
    if [ -n "$LATEST_URL" ] && [ "$LATEST_URL" != "null" ]; then
        curl -L -o "Plexamp.AppImage" "$LATEST_URL"
        
        print_msg "Rendendo Plexamp AppImage eseguibile..."
        chmod +x Plexamp.AppImage
        
        print_msg "Integrando Plexamp nel sistema..."
        ./Plexamp.AppImage --install
        
        print_msg "Avviando Plexamp..."
        ./Plexamp.AppImage &
    else
        print_error "Impossibile ottenere l'URL di download per Plexamp."
    fi
else
    print_error "jq non disponibile. Impossibile determinare l'URL di Plexamp."
fi

# ----- Installazione MH Audio Converter con Wine -----
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
if command -v wget &> /dev/null; then
    wget -O "$DOWNLOAD_PATH" "$DOWNLOAD_URL"
elif command -v curl &> /dev/null; then
    curl -L "$DOWNLOAD_URL" -o "$DOWNLOAD_PATH"
else
    print_warn "È necessario installare wget o curl per scaricare MH Audio Converter."
    # Prova ad installare wget
    sudo pacman -S --noconfirm wget
    if command -v wget &> /dev/null; then
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
if command -v yay &> /dev/null; then
    yay -Sc --noconfirm
fi

# Pulizia file temporanei
print_msg "Pulizia dei file temporanei..."
sudo rm -rf /var/tmp/*
sudo journalctl --vacuum-time=7d

print_msg "Aggiornamento e pulizia completati!"

echo -e "${BLUE}Sistema Pronto !!!${RESET}"