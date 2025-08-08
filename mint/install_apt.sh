#!/bin/bash


# Colori e messaggi in una sola funzione
_c() { case $1 in info) c="\033[0;34m"; p="[INFO]";; ok) c="\033[0;32m"; p="[✅ SUCCESS]";; warn) c="\033[0;33m"; p="[⚠️ WARNING]";; err) c="\033[0;31m"; p="[❌ ERROR]";; ask) c="\033[0;36m"; p="[🤔 ASK]";; esac; shift; echo -e "${c}${p}\033[0m $*"; }
print_msg()     { _c info "$@"; }
print_success() { _c ok "$@"; }
print_warn()    { _c warn "$@"; }
print_error()   { _c err "$@"; }
print_ask()     { _c ask "$@"; }
command_exists() { command -v "$1" &>/dev/null; }

# Definizione pacchetti per categoria
declare -A PKGS
PKGS["Sistema"]="ffmpeg timeshift baobab piper mediainfo-gui python3-pip openjdk-8-jre"
PKGS["Browser"]="firefox"
PKGS["Comunicazione"]="thunderbird"
PKGS["Multimedia"]="vlc handbrake mkvtoolnix-gui obs-studio vlc-plugin-access-extra"
PKGS["Produttività"]="default-jdk simple-scan filezilla gimp"
PKGS["Compatibilità"]="wine winbind winetricks xorriso libssl-dev ocl-icd-opencl-dev fakeroot xz-utils unzip"
PKGS["Giochi"]="steam lutris goverlay"
PKGS["Librerie giochi"]="libgnutls30 libgtk2.0-0 libgtk-3-0 libpulse0 alsa-base alsa-utils libasound2-plugins libgif7 libpng16-16 libopenal1 libxcomposite1 libxinerama1 libncurses6 vulkan-tools libvulkan1 mesa-vulkan-drivers ocl-icd-libopencl1 libva2 libgstreamer-plugins-base1.0-0 libsdl2-2.0-0 libv4l-0 libsqlite3-0"
PKGS["Librerie giochi 32-bit"]="libgl1:i386 libgnutls30:i386 libgtk2.0-0:i386 libgtk-3-0:i386 libpulse0:i386 libasound2-plugins:i386 libgif7:i386 libpng16-16:i386 libopenal1:i386 libxcomposite1:i386 libxinerama1:i386 libncurses6:i386 libvulkan1:i386 mesa-vulkan-drivers:i386 libva2:i386 libgstreamer-plugins-base1.0-0:i386 libsdl2-2.0-0:i386 libv4l-0:i386 libsqlite3-0:i386"


install_packages() {
    for cat in "${!PKGS[@]}"; do
        print_msg "Installazione pacchetti: $cat"
        sudo apt update && sudo apt install -y ${PKGS[$cat]} && print_success "$cat installati con successo" || print_error "Errore durante l'installazione di $cat"
    done
}

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
