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

# Aggiungi il repository di Plexamp e installa l'app
print_msg "Installazione Plexamp tramite AUR..."
yay -S --noconfirm plexamp-appimage

print_msg "Scaricando l'ultima versione di Plexamp AppImage..."
LATEST_URL=$(curl -s https://api.github.com/repos/plexinc/plexamp/releases/latest | jq -r .assets[0].browser_download_url)
curl -L -o "Plexamp.AppImage" "$LATEST_URL"

print_msg "Rendendo Plexamp AppImage eseguibile..."
chmod +x Plexamp.AppImage

print_msg "Integrando Plexamp nel sistema..."
./Plexamp.AppImage --install

print_msg "Avviando Plexamp..."
./Plexamp.AppImage &

# Installa Python, ffmpeg, pip e tk
print_msg "Installazione di Python e pacchetti di supporto..."
sudo pacman -S --noconfirm ffmpeg python-pip tk

# Installa Ollama
print_msg "Installazione di Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

# Installa pacchetti vari tramite yay
print_msg "Installazione di pacchetti AUR selezionati..."
yay -S --needed --noconfirm \
    p7zip \
    brave-bin \
    discord \
    enpass-bin \
    legendary \
    fancontrol-gui \
    freac \
    heroic-games-launcher-bin \
    jdownloader2 \
    localsend-bin \
    obs-studio \
    obsidian \
    occt \
    ollama-bin \
    qbittorrent \
    reaper \
    rustdesk-bin \
    winscp \
    steam \
    telegram-desktop \
    upscayl-bin \
    vlc \
    spotify \
    visual-studio-code-bin \
    mkvtoolnix-gui \
    firefox \
    thunderbird \
    mp3tag \
    freefilesync-bin \
    github-desktop-bin \
    baobab \
    jdk-openjdk

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
