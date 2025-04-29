#!/bin/bash

# Script per ripristinare Endeavour OS alle impostazioni di fabbrica
# Questo script deve essere eseguito come root (sudo)

# Colori per il testo
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funzione per stampare messaggi informativi
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Funzione per stampare avvisi
print_warning() {
    echo -e "${YELLOW}[AVVISO]${NC} $1"
}

# Funzione per stampare errori
print_error() {
    echo -e "${RED}[ERRORE]${NC} $1"
}

# Verifica se lo script è eseguito come root
if [ "$EUID" -ne 0 ]; then
    print_error "Questo script deve essere eseguito come root. Usa: sudo $0"
    exit 1
fi

# Chiedi conferma all'utente
echo -e "${RED}ATTENZIONE: Questo script ripristinerà Endeavour OS alle impostazioni di fabbrica.${NC}"
echo -e "${RED}Tutti i dati utente, le applicazioni installate e le configurazioni personalizzate andranno persi.${NC}"
echo -e "${RED}Assicurati di aver fatto un backup dei tuoi dati importanti prima di procedere.${NC}"
read -p "Sei sicuro di voler continuare? (s/N): " confirm
if [[ "$confirm" != [sS] ]]; then
    print_info "Operazione annullata."
    exit 0
fi

# Parte 1: Backup della lista dei pacchetti nativi (pacchetti base del sistema)
print_info "Creazione di un backup della lista dei pacchetti nativi..."
pacman -Qn > /tmp/pacchetti_nativi.txt

# Parte 2: Backup della lista dei pacchetti esplicitamente installati
print_info "Creazione di un backup della lista dei pacchetti esplicitamente installati..."
pacman -Qe > /tmp/pacchetti_espliciti.txt

# Parte 3: Rimuovere specificamente tutte le app installate dallo script di installazione
print_info "Rimozione delle applicazioni installate dallo script di installazione..."

# Rimozione specifica di Microsoft Edge con metodo alternativo
print_info "Rimozione di Microsoft Edge con metodo specifico..."
if [ -f "/opt/microsoft/msedge/microsoft-edge" ] || [ -d "/opt/microsoft/msedge" ]; then
    print_info "Microsoft Edge trovato, rimozione in corso..."
    # Rimuovi il pacchetto ufficiale se installato
    pacman -Rns microsoft-edge-stable --noconfirm 2>/dev/null || true
    pacman -Rns microsoft-edge-dev --noconfirm 2>/dev/null || true
    pacman -Rns microsoft-edge-beta --noconfirm 2>/dev/null || true
    
    # Se ancora presente, forza la rimozione della directory
    if [ -d "/opt/microsoft/msedge" ]; then
        print_info "Rimozione forzata della directory di Microsoft Edge..."
        rm -rf /opt/microsoft/msedge
    fi
    
    # Rimuovi eventuali file .desktop
    rm -f /usr/share/applications/microsoft-edge*.desktop 2>/dev/null || true
    
    # Rimuovi i link simbolici
    rm -f /usr/bin/microsoft-edge* 2>/dev/null || true
    
    print_info "Microsoft Edge rimosso con successo."
fi

# Elenco specifico di pacchetti da rimuovere (basato sullo script di installazione)
declare -a pacchetti_da_rimuovere=(
    # Utilità di sistema
    "ffmpeg" "p7zip" "p7zip-gui" "baobab" "fastfetch-git" "libratbag" "hdsentinel" 
    "fancontrol-gui" "piper" "freefilesync-bin"
    
    # Browser e comunicazione
    "firefox" "brave-bin" "discord" "telegram-desktop" "whatsapp-linux-desktop" 
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
    "jdk-openjdk" "enpass-bin" "skanpage" "python-pip" "tk"
    
    # Grafica
    "upscayl-bin" "occt"
    
    # AI
    "ollama-bin"
    
    # Compatibilità
    "wine"
    
    # AUR helper
    "yay" "yay-bin" "yay-git"
)

print_warning "Rimozione dei seguenti pacchetti specifici:"
for pkg in "${pacchetti_da_rimuovere[@]}"; do
    pacman -Rns "$pkg" --noconfirm 2>/dev/null || yay -Rns "$pkg" --noconfirm 2>/dev/null || true
    echo "  - $pkg rimosso o non trovato"
done

# Rimuovere anche altri pacchetti installati dall'utente (non base)
print_info "Rimozione di ulteriori pacchetti installati dall'utente..."
pacchetti_utente=$(comm -23 <(pacman -Qeq | sort) <(pacman -Qgq base base-devel gnome | sort))

if [ -n "$pacchetti_utente" ]; then
    print_warning "Rimozione dei seguenti pacchetti installati dall'utente:"
    echo "$pacchetti_utente"
    # Rimuovere i pacchetti installati dall'utente e le loro dipendenze non utilizzate
    pacman -Rns $pacchetti_utente --noconfirm
    print_info "Pacchetti utente rimossi con successo."
else
    print_info "Nessun pacchetto utente da rimuovere."
fi

# Parte 4: Pulizia pacchetti orfani
print_info "Rimozione dei pacchetti orfani..."
orphans=$(pacman -Qtdq)
if [ -n "$orphans" ]; then
    pacman -Rns $orphans --noconfirm
    print_info "Pacchetti orfani rimossi con successo."
else
    print_info "Nessun pacchetto orfano da rimuovere."
fi

# Parte 5: Pulizia delle cache di pacman
print_info "Pulizia della cache dei pacchetti..."
pacman -Scc --noconfirm

# Parte 6: Ripristino delle configurazioni di GNOME e altre configurazioni utente
print_info "Ripristino delle configurazioni di GNOME e altre configurazioni alle impostazioni di fabbrica..."
# Ottenere l'elenco degli utenti non di sistema
non_system_users=$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd)

for user in $non_system_users; do
    user_home=$(getent passwd "$user" | cut -d: -f6)
    
    # Verifica se l'utente esiste ed ha una home directory
    if [ -d "$user_home" ]; then
        print_info "Ripristino delle configurazioni per l'utente $user..."
        
        # Crea un comando che verrà eseguito come l'utente specifico
        su - "$user" -c "
            # Reset completo delle impostazioni GNOME
            print_msg() { echo \"\$1\"; }
            echo 'Ripristino dconf...'
            dconf reset -f /
            
            # Rimuovi file di configurazione e applicazioni
            echo 'Rimozione configurazioni specifiche...'
            rm -rf ~/.config/gnome-*
            rm -rf ~/.config/dconf
            rm -rf ~/.config/gtk-*
            rm -rf ~/.config/mimeapps.list
            rm -rf ~/.config/user-dirs.*
            rm -rf ~/.config/pulse
            rm -rf ~/.config/autostart/*
            rm -rf ~/.config/monitors.xml
            
            # Rimuovi cache e dati delle applicazioni
            echo 'Rimozione cache e dati applicazioni...'
            rm -rf ~/.local/share/gnome-*
            rm -rf ~/.local/share/applications/*
            rm -rf ~/.local/share/recently-used.xbel
            rm -rf ~/.local/share/keyrings/*
            rm -rf ~/.local/share/Trash/*
            rm -rf ~/.local/share/flatpak
            rm -rf ~/.local/state/*
            rm -rf ~/.cache/*
            
            # Reset delle estensioni GNOME
            echo 'Rimozione estensioni GNOME...'
            rm -rf ~/.local/share/gnome-shell/extensions/*
            
            # Reset delle configurazioni specifiche delle applicazioni
            echo 'Rimozione configurazioni applicazioni...'
            rm -rf ~/.mozilla
            rm -rf ~/.config/chromium
            rm -rf ~/.config/google-chrome
            # Rimozione completa delle configurazioni di Microsoft Edge
            rm -rf ~/.config/Microsoft
            rm -rf ~/.config/microsoft-edge*
            rm -rf ~/.config/microsoft-edge-dev
            rm -rf ~/.config/microsoft-edge-beta
            rm -rf ~/.cache/microsoft-edge*
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
            
            # Rimuovi Wine e prefissi Wine associati
            echo 'Rimozione prefissi Wine...'
            rm -rf ~/.wine*
            rm -rf ~/.wine_mhaudioconverter
            
            # Rimuovi file di configurazione che possono essere stati creati dalle applicazioni
            rm -rf ~/Plexamp.AppImage
            rm -rf ~/.ollama
        "
        
        print_info "Configurazioni ripristinate per l'utente $user."
    fi
done

# Parte 7: Pulizia delle directory temporanee del sistema
print_info "Pulizia delle directory temporanee del sistema..."
rm -rf /tmp/*
rm -rf /var/tmp/*

# Parte 8: Ripristino delle impostazioni di sistema
print_info "Ripristino delle impostazioni di sistema..."

# Ripristina file di configurazione di reflector
print_info "Ripristino della configurazione di reflector..."
if [ -f "/etc/xdg/reflector/reflector.conf.pacsave" ]; then
    mv /etc/xdg/reflector/reflector.conf.pacsave /etc/xdg/reflector/reflector.conf
elif [ -f "/etc/xdg/reflector/reflector.conf.pacnew" ]; then
    mv /etc/xdg/reflector/reflector.conf.pacnew /etc/xdg/reflector/reflector.conf
fi

# Reimpostare il prompt del terminale e altre configurazioni di sistema
cp /etc/skel/.bashrc /root/.bashrc

# Ripristina i file di configurazione degli utenti dalla directory skel
for user in $non_system_users; do
    user_home=$(getent passwd "$user" | cut -d: -f6)
    if [ -d "$user_home" ]; then
        print_info "Ripristino dei file di configurazione per l'utente $user..."
        
        # Rimuovi tutti i file di configurazione personalizzati
        rm -f "$user_home/.bashrc" "$user_home/.bash_profile" "$user_home/.bash_logout"
        rm -f "$user_home/.profile" "$user_home/.zshrc" "$user_home/.zprofile"
        
        # Copia i file dalla directory skel
        cp -f /etc/skel/.* "$user_home/" 2>/dev/null || true
        chown -R "$user":"$user" "$user_home"
    fi
done

# Ripristina configurazioni sistema specifiche
print_info "Ripristino delle configurazioni di sistema..."
# Ripristina configurazioni di pacman
cp -f /etc/pacman.conf.pacnew /etc/pacman.conf 2>/dev/null || true

# Rimuovi eventuali repository AUR aggiunti
sed -i '/^\[custom\]/,/^\[/ d' /etc/pacman.conf
sed -i '/^Include = \/etc\/pacman.d\/custom/d' /etc/pacman.conf

# Parte 9: Ripristino dei servizi di sistema
print_info "Ripristino dei servizi di sistema alle impostazioni predefinite..."
systemctl set-default graphical.target

# Disabilita servizi non standard potenzialmente installati
print_info "Disabilitazione di servizi non standard..."
# Lista di servizi comuni che potrebbero essere stati installati
declare -a servizi_da_disabilitare=(
    "plexamp" "ollama" "steam" "discord" "teamviewer" "rustdesk"
    "docker" "libvirtd" "syncthing" "syncthing-gtk" "dropbox"
)

# Disabilita e ferma i servizi se esistono
for servizio in "${servizi_da_disabilitare[@]}"; do
    if systemctl list-unit-files --type=service | grep -q "$servizio"; then
        print_info "Disabilitazione del servizio $servizio..."
        systemctl stop "$servizio" 2>/dev/null || true
        systemctl disable "$servizio" 2>/dev/null || true
    fi
done

# Abilita servizi predefiniti se sono stati disabilitati
systemctl enable gdm.service
systemctl enable NetworkManager.service

# Parte 10: Pulizia dei log di sistema e mirror
print_info "Pulizia dei log di sistema..."
journalctl --vacuum-time=1d

# Aggiorna il mirrorlist per ripristinare le impostazioni di default
print_info "Ripristino della lista dei mirror..."
if command -v reflector &> /dev/null; then
    print_info "Aggiornamento mirrorlist con reflector..."
    reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
fi

# Rimuovi yay e altre utility AUR se ancora presenti
print_info "Rimozione di eventuali helper AUR residui..."
rm -rf /usr/bin/yay 2>/dev/null || true
rm -rf /usr/bin/paru 2>/dev/null || true
pacman -Rns yay yay-bin yay-git paru paru-bin --noconfirm 2>/dev/null || true

# Verifica finale per Microsoft Edge
print_info "Verifica finale per Microsoft Edge..."
if [ -f "/opt/microsoft/msedge/microsoft-edge" ] || [ -d "/opt/microsoft/msedge" ]; then
    print_warning "Microsoft Edge è ancora presente nel sistema. Tentativo di rimozione forzata..."
    rm -rf /opt/microsoft
    # Rimuovi eventuali pacchetti orfani che potrebbero contenere componenti di Edge
    pacman -Rns $(pacman -Qtdq) --noconfirm 2>/dev/null || true
fi

# Rimuovi eventuali riferimenti a Microsoft Edge in /etc
find /etc -name "*microsoft*" -o -name "*edge*" | xargs rm -rf 2>/dev/null || true

print_info "Ripristino del database pacman..."
pacman -Syy

print_info "Ripristino ai valori di fabbrica completato con successo!"
echo -e "${BLUE}===========================================${NC}"
echo -e "${GREEN}SISTEMA RIPRISTINATO ALLE IMPOSTAZIONI DI FABBRICA${NC}"
echo -e "${BLUE}===========================================${NC}"
print_info "Si consiglia di riavviare il sistema per applicare tutte le modifiche."
read -p "Vuoi riavviare il sistema adesso? (s/N): " reboot_now
if [[ "$reboot_now" == [sS] ]]; then
    print_info "Il sistema verrà riavviato tra 5 secondi..."
    sleep 5
    reboot
else
    print_info "Ricordati di riavviare il sistema manualmente quando è conveniente."
fi

exit 0