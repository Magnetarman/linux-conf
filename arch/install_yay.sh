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
PKGS["AUR"]="visual-studio-code-bin google-chrome onlyoffice-bin enpass-bin github-desktop-bin brave-bin"
PKGS["Sistema"]="ffmpeg timeshift baobab piper mediainfo python-pip"
PKGS["Browser"]="firefox"
PKGS["Multimedia"]="vlc handbrake mkvtoolnix-gui obs-studio"
PKGS["Produttività"]="jdk-openjdk simple-scan filezilla gimp"
PKGS["Compatibilità"]="wine winbind winetricks xorriso openssl ocl-icd fakeroot xz unzip"
PKGS["Giochi"]="steam lutris goverlay"
PKGS["Librerie giochi"]="gnutls gtk2 gtk3 libpulse alsa-utils alsa-plugins giflib libpng openal libxcomposite libxinerama ncurses vulkan-tools vulkan-icd-loader mesa vulkan-driver libva gstreamer sdl2 v4l-utils sqlite"
PKGS["Librerie giochi 32-bit"]="lib32-libgl lib32-gnutls lib32-gtk2 lib32-gtk3 lib32-libpulse lib32-alsa-plugins lib32-giflib lib32-libpng lib32-openal lib32-libxcomposite lib32-libxinerama lib32-ncurses lib32-vulkan-icd-loader lib32-mesa lib32-libva lib32-gstreamer lib32-sdl2 lib32-v4l-utils lib32-sqlite"


install_packages() {
    local aur_pkgs=()
    local first=1
    for cat in "${!PKGS[@]}"; do
        if [[ "$cat" == "AUR" ]]; then
            for pkg in ${PKGS[$cat]}; do
                aur_pkgs+=("$pkg")
            done
        else
            print_msg "Installazione pacchetti: $cat"
            if (( first )); then
                sudo pacman -Syu --noconfirm --needed ${PKGS[$cat]} && print_success "$cat installati con successo" || print_error "Errore durante l'installazione di $cat"
                first=0
            else
                sudo pacman -S --noconfirm --needed ${PKGS[$cat]} && print_success "$cat installati con successo" || print_error "Errore durante l'installazione di $cat"
            fi
        fi
    done
    if [ ${#aur_pkgs[@]} -gt 0 ]; then
        if command_exists yay; then
            print_msg "Installazione pacchetti AUR: ${aur_pkgs[*]}"
            yay -S --noconfirm --needed "${aur_pkgs[@]}" && print_success "AUR installati con successo" || print_error "Errore durante l'installazione dei pacchetti AUR"
        else
            print_warn "Pacchetti AUR richiesti ma yay non trovato. Installazione saltata."
        fi
    fi
}

# Installa applicazioni Flatpak
install_flatpak_apps() {
    setup_flatpak
    local flatpak_apps=(
        org.telegram.desktop org.localsend.localsend_app com.plexamp.Plexamp org.upscayl.Upscayl com.rustdesk.RustDesk org.freac.freac org.freefilesync.FreeFileSync io.github.jonmagon.kdiskmark com.geeks3d.furmark io.github.wiiznokes.fan-control org.gnome.EasyTAG dev.edfloreshz.Tasks org.jdownloader.JDownloader com.spotify.Client org.cryptomator.Cryptomator com.ktechpit.whatsie io.github.peazip.PeaZip eu.betterbird.Betterbird
    )
    for app in "${flatpak_apps[@]}"; do
        flatpak info "$app" &>/dev/null && print_warn "$app è già installato" || (flatpak install flathub "$app" -y && print_success "$app installato con successo" || print_error "Installazione di $app fallita")
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
    install_flatpak_apps
    return_to_main
}

# Avvia lo script
main
