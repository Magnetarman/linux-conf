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

# Aggiorna la lista dei mirror
print_msg "Aggiornamento della lista dei mirror..."
sudo reflector --country 'Italy,Germany,France' --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

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
LATEST_URL=$(curl -s https://api.github.com/repos/plexinc/plexamp/releases/latest | jq -r .assets[0].browser_download_url)
curl -L -o "Plexamp.AppImage" "$LATEST_URL"

print_msg "Rendendo Plexamp AppImage eseguibile..."
chmod +x Plexamp.AppImage

print_msg "Integrando Plexamp nel sistema..."
./Plexamp.AppImage --install

print_msg "Avviando Plexamp..."
./Plexamp.AppImage &

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
    # Continua comunque con il resto dell'installazione
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
sudo pacman -Rns --noconfirm $(pacman -Qtdq) 2>/dev/null || echo "Nessun pacchetto orfano da rimuovere."

# Pulizia cache pacman
print_msg "Pulizia cache pacman..."
sudo paccache -r
sudo paccache -rk1

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