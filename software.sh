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
    legendary-git \
    fancontrol-gui \
    freac \
    gog-galaxy-bin \
    jdownloader2 \
    lm-studio-bin \
    local-by-flywheel \
    localsend-bin \
    obs-studio \
    obsidian \
    occt \
    playnite \
    plexamp-appimage \
    protonvpn \
    qbittorrent \
    reaper \
    rustdesk-bin \
    windscribe-cli \
    winscp \
    steam \
    telegram-desktop \
    treefishl \
    twinkle-tray \
    ultimate-vocal-remover-gui \
    upscayl-bin \
    vlc \
    spotify \
    visual-studio-code-bin \
    mkvtoolnix-gui \
    firefox \
    thunderbird \
    mp3tag \
    freefilesync-bin \
    github-desktop-bin