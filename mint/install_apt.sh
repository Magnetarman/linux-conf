#!/bin/bash

# Variabili di colore
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Configurazione Messaggi
print_msg() { echo -e "${BLUE}[INFO]${RESET} $1"; }
print_success() { echo -e "${GREEN}[✅ SUCCESS]${RESET} $1"; }
print_warn() { echo -e "${YELLOW}[⚠️ WARNING]${RESET} $1"; }
print_error() { echo -e "${RED}[❌ ERROR]${RESET} $1"; }
print_ask() { echo -e "${CYAN}[🤔 ASK]${RESET} $1"; }

# Funzione per verificare se un comando esiste
command_exists() {
    command -v "$1" &>/dev/null
}

# Funzione per installare i pacchetti
install_packages() {
    category="$1"
    shift
    print_msg "Installazione pacchetti: $category"
    sudo apt update && sudo apt install -y "$@" && print_success "$category installati con successo" || print_error "Errore durante l'installazione di $category"
}

# Installazione pacchetti
install_packages "Sistema" ffmpeg timeshift p7zip-full p7zip-rar baobab piper mediainfo-gui python3-pip
install_packages "Browser" firefox
install_packages "Comunicazione" thunderbird
install_packages "Multimedia" vlc handbrake mkvtoolnix-gui obs-studio vlc-plugin-access-extra
install_packages "Download" qbittorrent
install_packages "Produttività" default-jdk simple-scan
install_packages "Compatibilità" wine
install_packages "Giochi" steam lutris goverlay
install_packages "Librerie giochi" libgnutls30 libgtk2.0-0 libgtk-3-0 libpulse0 alsa-base alsa-utils libasound2-plugins libgif7 libpng16-16 libopenal1 libxcomposite1 libxinerama1 libncurses6 vulkan-tools libvulkan1 mesa-vulkan-drivers ocl-icd-libopencl1 libva2 libgstreamer-plugins-base1.0-0 libsdl2-2.0-0 libv4l-0 libsqlite3-0
install_packages "Librerie giochi 32-bit" libgl1:i386 libgnutls30:i386 libgtk2.0-0:i386 libgtk-3-0:i386 libpulse0:i386 libasound2-plugins:i386 libgif7:i386 libpng16-16:i386 libopenal1:i386 libxcomposite1:i386 libxinerama1:i386 libncurses6:i386 libvulkan1:i386 mesa-vulkan-drivers:i386 libva2:i386 libgstreamer-plugins-base1.0-0:i386 libsdl2-2.0-0:i386 libv4l-0:i386 libsqlite3-0:i386

# Funzione per ritornare allo script principale
return_to_main() {
    print_msg "Ritornando allo script principale..."
    exit 0
}

# Funzione principale
main() {
    install_packages
    return_to_main
}

# Avvia lo script
main
