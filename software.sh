#!/bin/bash
# Aggiorna il sistema
echo "Aggiornando il sistema..."
sudo pacman -Syu --noconfirm

# Installa yay (AUR helper) se non è già presente
if ! command -v yay &> /dev/null; then
    echo "yay non trovato. Installazione..."
    sudo pacman -S yay --noconfirm
fi

# Aggiungi il repository di Plexamp su AUR
echo "Aggiungendo il repository Plexamp tramite AUR..."
yay -S --noconfirm plexamp-appimage

# Scarica l'ultima versione di Plexamp AppImage
echo "Scaricando l'AppImage di Plexamp..."
LATEST_URL=$(curl -s https://api.github.com/repos/plexinc/plexamp/releases/latest | jq -r .assets[0].browser_download_url)
curl -L -o "Plexamp.AppImage" "$LATEST_URL"

# Rendi il file AppImage eseguibile
echo "Rendendo Plexamp AppImage eseguibile..."
chmod +x Plexamp.AppImage

# Aggiungi Plexamp al menu delle applicazioni (opzionale, se vuoi l'integrazione)
echo "Integrare Plexamp nel sistema..."
./Plexamp.AppImage --install

# Avvia Plexamp
echo "Avviando Plexamp..."
./Plexamp.AppImage &

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