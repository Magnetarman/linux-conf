#!/bin/bash

# Script unificato per ripristinare Endeavour OS/Arch Linux alle impostazioni di fabbrica
# Questo script deve essere eseguito come root (sudo)

# Colori per il testo
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funzioni per la formattazione dei messaggi
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[AVVISO]${NC} $1"; }
error() { echo -e "${RED}[ERRORE]${NC} $1"; }

# Verifica permessi root
if [ "$EUID" -ne 0 ]; then
    error "Questo script deve essere eseguito come root. Usa: sudo $0"
    exit 1
fi

# Chiedi conferma all'utente
echo -e "${RED}ATTENZIONE: Questo script ripristinerà il sistema alle impostazioni di fabbrica.${NC}"
echo -e "${RED}Tutti i dati utente, le applicazioni installate e le configurazioni personalizzate andranno persi.${NC}"
echo -e "${RED}Assicurati di aver fatto un backup dei tuoi dati importanti prima di procedere.${NC}"
read -p "Sei sicuro di voler continuare? (s/N): " confirm
if [[ "$confirm" != [sS] ]]; then
    info "Operazione annullata."
    exit 0
fi

# Backup dei pacchetti
info "Creazione di un backup delle liste dei pacchetti..."
pacman -Qn > /tmp/pacchetti_nativi.txt
pacman -Qe > /tmp/pacchetti_espliciti.txt

# Elenco completo dei pacchetti da rimuovere (unione dei due script)
declare -a pacchetti_da_rimuovere=(
    # Utilità di sistema
    "ffmpeg" "p7zip" "p7zip-gui" "baobab" "fastfetch-git" "libratbag" "hdsentinel" 
    "fancontrol-gui" "piper" "freefilesync-bin"
    
    # Browser e comunicazione
    "firefox" "brave-bin" "discord" "zoom" "telegram-desktop" "whatsapp-linux-desktop" 
    "thunderbird" "localsend-bin" "google-chrome" "microsoft-edge-stable" "microsoft-edge-dev" "microsoft-edge-beta"
    
    # Multimedia e intrattenimento
    "vlc" "handbrake" "mkvtoolnix-gui" "freac" "mp3tag" "obs-studio" 
    "youtube-to-mp3" "spotify" "plexamp-appimage" "reaper"
    
    # Download e condivisione
    "qbittorrent" "jdownloader2" "winscp" "rustdesk-bin"
    
    # Gaming
    "steam" "heroic-games-launcher-bin" "legendary"
    
    # Produttività
    "obsidian" "visual-studio-code-bin" "github-desktop-bin" "onlyoffice-bin" 
    "jdk-openjdk" "enpass-bin" "skanpage" "simple-scan" "python-pip" "tk"
    
    # Grafica
    "upscayl-bin" "occt"
    
    # AI
    "ollama-bin"
    
    # Compatibilità
    "wine"
    
    # AUR helper
    "yay" "yay-bin" "yay-git" "paru" "paru-bin"
)

# Rimozione delle applicazioni
warn "Rimozione dei pacchetti installati..."
for pkg in "${pacchetti_da_rimuovere[@]}"; do
    pacman -Rns "$pkg" --noconfirm 2>/dev/null || yay -Rns "$pkg" --noconfirm 2>/dev/null || true
done

# Rimozione specifica di Microsoft Edge con metodo completo
info "Rimozione completa di Microsoft Edge..."
if [ -f "/opt/microsoft/msedge/microsoft-edge" ] || [ -d "/opt/microsoft/msedge" ]; then
    # Rimuovi il pacchetto ufficiale se installato
    pacman -Rns microsoft-edge-stable --noconfirm 2>/dev/null || true
    pacman -Rns microsoft-edge-dev --noconfirm 2>/dev/null || true
    pacman -Rns microsoft-edge-beta --noconfirm 2>/dev/null || true
    
    # Forza la rimozione della directory
    rm -rf /opt/microsoft
    rm -f /usr/share/applications/microsoft-edge*.desktop 2>/dev/null || true
    rm -f /usr/bin/microsoft-edge* 2>/dev/null || true
fi

# Rimuovere anche pacchetti installati dall'utente (non base)
info "Rimozione di ulteriori pacchetti installati dall'utente..."
pacchetti_utente=($(comm -23 <(pacman -Qeq | sort) <(pacman -Qgq base base-devel gnome | sort)))

if [ ${#pacchetti_utente[@]} -gt 0 ]; then
    warn "Rimozione dei seguenti pacchetti installati dall'utente:"
    printf '%s\n' "${pacchetti_utente[@]}"
    pacman -Rns ${pacchetti_utente[@]} --noconfirm 2>/dev/null || true
fi

# Rimozione pacchetti orfani
info "Rimozione dei pacchetti orfani..."
orphans=$(pacman -Qtdq)
if [ -n "$orphans" ]; then
    pacman -Rns $orphans --noconfirm
fi

# Pulizia delle cache di pacman
info "Pulizia della cache dei pacchetti..."
pacman -Scc --noconfirm

# Ripristino configurazioni utente
info "Ripristino delle configurazioni utente..."
# Ottenere l'elenco degli utenti non di sistema
non_system_users=$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd)

for user in $non_system_users; do
    user_home=$(getent passwd "$user" | cut -d: -f6)
    
    if [ -d "$user_home" ]; then
        info "Ripristino configurazioni per l'utente $user..."
        
        # Crea un comando che verrà eseguito come l'utente specifico
        su - "$user" -c "
            # Reset completo di dconf
            dconf reset -f /
            
            # Rimozione configurazioni
            rm -rf ~/.config
            rm -rf ~/.cache
            rm -rf ~/.local
            rm -rf ~/.mozilla
            rm -rf ~/.config/chromium
            rm -rf ~/.config/google-chrome
            rm -rf ~/.config/Microsoft
            rm -rf ~/.config/microsoft-edge*
            rm -rf ~/.config/discord
            rm -rf ~/.config/Code
            rm -rf ~/.config/spotify
            rm -rf ~/.config/plexamp
            rm -rf ~/.config/obs-studio
            rm -rf ~/.config/vlc
            rm -rf ~/.config/qBittorrent
            rm -rf ~/.steam
            rm -rf ~/.heroic
            rm -rf ~/.wine*
            rm -rf ~/.thunderbird
            rm -rf ~/.fzf
            rm -rf ~/.zoxide
            rm -rf ~/.mybash
            
            # Rimozione file di configurazione shell
            rm -f ~/.bashrc
            rm -f ~/.bash_profile
            rm -f ~/.bash_logout
            rm -f ~/.profile
            rm -f ~/.zshrc
            rm -f ~/.zprofile
            
            # Rimozione applicazioni residue
            rm -rf ~/Plexamp.AppImage
            rm -rf ~/.ollama
            
            # Ricreazione directory base
            mkdir -p ~/.config ~/.cache ~/.local
        "
        
        # Ripristino file di configurazione dalla directory skel
        cp -f /etc/skel/.* "$user_home/" 2>/dev/null || true
        chown -R "$user":"$user" "$user_home"
        
        info "Configurazioni ripristinate per l'utente $user."
    fi
done

# Ripristino delle configurazioni di sistema
info "Ripristino delle configurazioni di sistema..."

# Ripristina file configurazione di pacman
if [ -f "/etc/pacman.conf.pacnew" ]; then
    cp -f /etc/pacman.conf.pacnew /etc/pacman.conf
fi

# Rimuovi eventuali repository AUR aggiunti
sed -i '/^\[custom\]/,/^\[/ d' /etc/pacman.conf
sed -i '/^Include = \/etc\/pacman.d\/custom/d' /etc/pacman.conf

# Ripristino configurazione di reflector
if [ -f "/etc/xdg/reflector/reflector.conf.pacsave" ]; then
    mv /etc/xdg/reflector/reflector.conf.pacsave /etc/xdg/reflector/reflector.conf
elif [ -f "/etc/xdg/reflector/reflector.conf.pacnew" ]; then
    mv /etc/xdg/reflector/reflector.conf.pacnew /etc/xdg/reflector/reflector.conf
fi

# Aggiorna il mirrorlist
info "Ripristino della lista dei mirror..."
if command -v reflector &> /dev/null; then
    reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
fi

# Pulizia file e configurazioni sistema
info "Pulizia file e configurazioni di sistema..."
rm -rf /usr/lib/systemd/system/fancontrol.service
rm -rf /etc/fancontrol.conf
rm -rf /usr/local/bin/starship
rm -rf /usr/bin/yay /usr/bin/paru
find /etc -name "*microsoft*" -o -name "*edge*" | xargs rm -rf 2>/dev/null || true

# Ripristina file di configurazione del root
cp /etc/skel/.bashrc /root/.bashrc

# Ripristino dei servizi di sistema
info "Ripristino dei servizi di sistema..."
systemctl set-default graphical.target

# Elenco servizi da disabilitare
declare -a servizi_da_disabilitare=(
    "plexamp" "ollama" "steam" "discord" "teamviewer" "rustdesk"
    "docker" "libvirtd" "syncthing" "syncthing-gtk" "dropbox"
)

# Disabilita e ferma i servizi
for servizio in "${servizi_da_disabilitare[@]}"; do
    if systemctl list-unit-files --type=service | grep -q "$servizio"; then
        info "Disabilitazione del servizio $servizio..."
        systemctl stop "$servizio" 2>/dev/null || true
        systemctl disable "$servizio" 2>/dev/null || true
    fi
done

# Abilita servizi predefiniti
systemctl enable gdm.service
systemctl enable NetworkManager.service

# Pulizia dei log e directory temporanee
info "Pulizia dei log e directory temporanee..."
journalctl --vacuum-time=1d
rm -rf /tmp/*
rm -rf /var/tmp/*

# Aggiornamento database pacman
info "Aggiornamento database pacman..."
pacman -Syy

# Completamento
echo -e "${BLUE}===========================================${NC}"
echo -e "${GREEN}SISTEMA RIPRISTINATO ALLE IMPOSTAZIONI DI FABBRICA${NC}"
echo -e "${BLUE}===========================================${NC}"
info "Si consiglia di riavviare il sistema per applicare tutte le modifiche."
read -p "Vuoi riavviare il sistema adesso? (s/N): " reboot_now
if [[ "$reboot_now" == [sS] ]]; then
    info "Il sistema verrà riavviato tra 5 secondi..."
    sleep 5
    reboot
else
    info "Ricordati di riavviare il sistema manualmente quando è conveniente."
fi

exit 0