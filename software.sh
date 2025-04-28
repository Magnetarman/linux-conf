#!/bin/bash

# Controlla se yay è installato
if ! command -v yay &> /dev/null; then
    echo "Installazione di yay..."
    sudo pacman -S --needed git base-devel
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    cd ..
    rm -rf yay
fi

# Aggiorna il sistema e installa Python, ffmpeg, pip e tk
echo "Installazione Python e pacchetti di supporto..."
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm ffmpeg python-pip tk

# Installa Ollama
echo "Installazione Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

# Installa i pacchetti desiderati con yay
echo "Installazione dei pacchetti AUR tramite yay..."
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

# Esecuzione dello script Python install-vocal-remover.py
echo "Installazione vocal remover in corso..."
python3 "$(dirname "$0")/install-vocal-remover.py"

echo "Installazione completata con successo."