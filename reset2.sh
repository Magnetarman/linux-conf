
#!/bin/bash

# Script per riportare Arch/EndeavourOS alle impostazioni di fabbrica
# Versione estesa e approfondita - by ChatGPT per Francesco

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[ATTENZIONE]${NC} $1"; }
error() { echo -e "${RED}[ERRORE]${NC} $1"; }

# Verifica permessi
if [ "$EUID" -ne 0 ]; then
    error "Questo script va eseguito come root (sudo)."
    exit 1
fi

echo -e "${RED}ATTENZIONE: Tutti i dati utente, le app installate e le configurazioni personalizzate verranno eliminati.${NC}"
read -p "Vuoi continuare? (s/N): " conferma
if [[ "$conferma" != [sS] ]]; then
    info "Operazione annullata."
    exit 0
fi

# Backup pacchetti
info "Backup elenco pacchetti..."
pacman -Qn > /tmp/pacchetti_nativi.txt
pacman -Qe > /tmp/pacchetti_espliciti.txt

# Pacchetti da rimuovere (da install.sh)
declare -a pacchetti=(
    ffmpeg p7zip p7zip-gui baobab fastfetch-git libratbag hdsentinel piper freefilesync-bin
    firefox brave-bin discord zoom telegram-desktop whatsapp-linux-desktop thunderbird localsend-bin google-chrome microsoft-edge-stable
    vlc handbrake mkvtoolnix-gui freac mp3tag obs-studio youtube-to-mp3 spotify plexamp-appimage reaper
    qbittorrent jdownloader2 winscp rustdesk-bin
    steam heroic-games-launcher-bin legendary
    obsidian visual-studio-code-bin github-desktop-bin onlyoffice-bin jdk-openjdk enpass-bin simple-scan
    upscayl-bin occt
    ollama-bin wine yay yay-bin yay-git
)

warn "Rimozione pacchetti installati..."
for pkg in "${pacchetti[@]}"; do
    pacman -Rns "$pkg" --noconfirm 2>/dev/null || yay -Rns "$pkg" --noconfirm 2>/dev/null || true
done

# Pacchetti utente aggiuntivi
info "Rimozione pacchetti aggiuntivi..."
user_pkgs=($(comm -23 <(pacman -Qeq | sort) <(pacman -Qgq base base-devel | sort)))
if [ -n "$user_pkgs" ]; then
    pacman -Rns ${user_pkgs[@]} --noconfirm
fi

# Pacchetti orfani
orphans=$(pacman -Qtdq)
[ -n "$orphans" ] && pacman -Rns $orphans --noconfirm

# Pulizia cache
info "Pulizia cache pacman..."
pacman -Scc --noconfirm

# Utenti normali
utenti=$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd)

for utente in $utenti; do
    home=$(eval echo ~$utente)
    info "Pulizia configurazioni per $utente..."

    su - "$utente" -c '
        dconf reset -f /
        rm -rf ~/.config ~/.cache ~/.local ~/.mozilla ~/.wine* ~/.bashrc ~/.zshrc ~/.bash_profile ~/.bash_logout
        rm -rf ~/Plexamp.AppImage ~/.ollama ~/.fzf ~/.zoxide ~/.mybash
        rm -rf ~/.steam ~/.heroic ~/.config/spotify ~/.config/discord ~/.config/Code ~/.config/microsoft*
        mkdir -p ~/.config ~/.cache ~/.local
    '

    cp /etc/skel/.bashrc "$home/"
    chown -R "$utente:$utente" "$home"
done

# File e configurazioni di sistema
info "Pulizia configurazioni globali..."
rm -rf /opt/microsoft
rm -rf /usr/share/applications/microsoft-edge*.desktop
rm -rf /usr/lib/systemd/system/fancontrol.service
rm -rf /etc/fancontrol.conf
rm -rf /usr/local/bin/starship
rm -rf /usr/bin/yay /usr/bin/paru

# Config pacman
sed -i '/^\[custom\]/,/^\[/ d' /etc/pacman.conf
sed -i '/^Include = \/etc\/pacman\.d\/custom/d' /etc/pacman.conf
cp -f /etc/pacman.conf.pacnew /etc/pacman.conf 2>/dev/null || true

# Reset mirrorlist
if command -v reflector &> /dev/null; then
    reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
fi

# Log e temp
info "Pulizia log e temporanei..."
journalctl --vacuum-time=1d
rm -rf /tmp/* /var/tmp/*

# Servizi
info "Ripristino servizi di default..."
systemctl set-default graphical.target
systemctl enable gdm.service
systemctl enable NetworkManager.service

servizi_custom=(
    plexamp ollama steam discord teamviewer rustdesk docker libvirtd syncthing dropbox
)
for servizio in "${servizi_custom[@]}"; do
    systemctl stop "$servizio" 2>/dev/null || true
    systemctl disable "$servizio" 2>/dev/null || true
done

info "Aggiornamento database pacman..."
pacman -Syy

info "Reset completato. Riavvio consigliato."
read -p "Vuoi riavviare ora? (s/N): " reboot_confirm
if [[ "$reboot_confirm" == [sS] ]]; then
    reboot
fi
