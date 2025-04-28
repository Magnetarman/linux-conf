# Prima installiamo yay se non è già installato
if ! command -v yay &> /dev/null; then
    echo "Installazione di yay..."
    sudo pacman -S --needed git base-devel
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    cd ..
    rm -rf yay
fi

# Ora installiamo tutti i pacchetti richiesti
yay -S --needed \
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
    baobab

# Per i pacchetti che non sono stati trovati nell'AUR, mostriamo un messaggio
echo "===================================================================="
echo "NOTA: I seguenti pacchetti non sono stati trovati nell'AUR o potrebbero avere nomi diversi:"
echo "- Local by Flywheel"
echo "- Ultimate Vocal Remover"
echo "===================================================================="
echo "Puoi cercare alternative per questi pacchetti usando: yay -Ss nome_pacchetto"