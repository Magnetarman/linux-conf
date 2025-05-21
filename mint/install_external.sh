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

# Controlla ed installa comandi mancanti
check_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        print_msg "Installazione $1..."
        sudo apt-get install -y "$1" || print_error "Impossibile installare $1"
    }
}

# Installa un pacchetto DEB con gestione degli errori migliorata
install_deb() {
    local pkg="$1" url="$2"
    print_msg "Scarico e installo pacchetto DEB: $pkg"

    # Controlla se il download è necessario (alcune URL potrebbero essere percorsi locali)
    if [[ "$url" =~ ^https?:// ]]; then
        print_warn "Download da $url"
        if ! wget -O "/tmp/$pkg" "$url"; then
            print_error "Download fallito per $pkg"
            return 1
        fi
        local pkg_path="/tmp/$pkg"
    else
        local pkg_path="$url"
    fi

    # Controlla che il file scaricato sia un DEB valido
    if ! file "$pkg_path" | grep -q "Debian binary package"; then
        print_error "File non valido per $pkg - non è un pacchetto DEB valido"
        return 1
    fi

    # Installa il pacchetto
    if sudo dpkg -i "$pkg_path"; then
        print_success "$pkg installato con successo"
    else
        print_warn "Risoluzione dipendenze per $pkg"
        sudo apt-get install -f -y
        if sudo dpkg -i "$pkg_path"; then
            print_success "$pkg installato con successo dopo risoluzione dipendenze"
        else
            print_error "Installazione di $pkg fallita"
            return 1
        fi
    fi

    # Pulisci il file scaricato se necessario
    [[ "$url" =~ ^https?:// ]] && rm -f "$pkg_path"
    return 0
}

# Setup dei repository
setup_repos() {
    # Crea directory e controlla comandi richiesti
    mkdir -p ~/.local/bin ~/.gnupg
    sudo mkdir -p /usr/share/keyrings /etc/apt/keyrings /etc/apt/sources.list.d
    for cmd in curl wget gpg apt-transport-https; do check_cmd "$cmd"; done

    # Definizione repository
    declare -A repos=(
        ["brave"]="curl -fsSL https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg | sudo tee /usr/share/keyrings/brave-browser.gpg > /dev/null && echo 'deb [signed-by=/usr/share/keyrings/brave-browser.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main' | sudo tee /etc/apt/sources.list.d/brave-browser.list"
        ["vscode"]="curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/packages.microsoft.gpg > /dev/null && echo 'deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main' | sudo tee /etc/apt/sources.list.d/vscode.list"
        ["chrome"]="curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | sudo tee /usr/share/keyrings/google-linux-signing-key.gpg > /dev/null && echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/google-linux-signing-key.gpg] http://dl.google.com/linux/chrome/deb/ stable main' | sudo tee /etc/apt/sources.list.d/google-chrome.list"
        ["onlyoffice"]="wget -qO- 'https://download.onlyoffice.com/GPG-KEY-ONLYOFFICE' | sudo gpg --dearmor --output /etc/apt/keyrings/onlyoffice.gpg && echo 'deb [signed-by=/etc/apt/keyrings/onlyoffice.gpg] https://download.onlyoffice.com/repo/debian squeeze main' | sudo tee /etc/apt/sources.list.d/onlyoffice.list"
        ["enpass"]="curl -fsSL https://apt.enpass.io/keys/enpass-linux.key | gpg --dearmor | sudo tee /etc/apt/keyrings/enpass.gpg > /dev/null && echo 'deb [signed-by=/etc/apt/keyrings/enpass.gpg] https://apt.enpass.io/ stable main' | sudo tee /etc/apt/sources.list.d/enpass.list"
        ["github-desktop"]="curl -fsSL https://apt.packages.shiftkey.dev/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/shiftkey.gpg > /dev/null && echo 'deb [arch=amd64 signed-by=/etc/apt/keyrings/shiftkey.gpg] https://apt.packages.shiftkey.dev/ubuntu/ any main' | sudo tee /etc/apt/sources.list.d/shiftkey.list"
    )

    # Aggiunta repository
    for repo in "${!repos[@]}"; do
        print_msg "Aggiungo repository: $repo"
        eval "${repos[$repo]}" || print_error "Errore aggiungendo $repo"
    done

    # Aggiorna apt
    print_warn "Aggiorno apt..."
    sudo apt-get update
}

# Installa pacchetti dai repository
install_pkgs() {
    # Definisci pacchetti
    declare -A pkgs=(
        ["brave"]="brave-browser"
        ["vscode"]="code"
        ["chrome"]="google-chrome-stable"
        ["onlyoffice"]="onlyoffice-desktopeditors"
        ["enpass"]="enpass"
        ["github-desktop"]="github-desktop"
    )

    # Installa pacchetti
    for src in "${!pkgs[@]}"; do
        pkg="${pkgs[$src]}"
        print_msg "Installo $pkg"
        sudo apt-get install -y "$pkg" || print_error "Errore installando $pkg"
    done
}

# Installa WhatsApp
install_whatsapp() {
    print_msg "Installazione WhatsApp..."
    snap install whatsapp-desktop-client
}

# Installa Spotify con metodo alternativo
install_spotify() {
    print_warn "Installazione Spotify (metodo alternativo)..."

    # Prima rimuovi eventuali installazioni precedenti
    sudo apt-get remove -y spotify-client || true

    # Metodo 1: Prova con --allow-unauthenticated
    print_msg "Tentativo 1: Installazione Spotify con --allow-unauthenticated"
    if sudo apt-get install --allow-unauthenticated -y spotify-client; then
        print_success "Spotify installato con successo (metodo 1)"
        return 0
    fi

    # Metodo 2: Prova con --allow-insecure
    print_msg "Tentativo 2: Installazione Spotify con --allow-insecure"
    if sudo apt-get install --allow-insecure=yes -y spotify-client; then
        print_success "Spotify installato con successo (metodo 2)"
        return 0
    fi

    # Metodo 3: Flatpak come ultima risorsa
    print_msg "Tentativo 4: Installazione Spotify via Flatpak"
    setup_flatpak
    if flatpak install flathub com.spotify.Client -y; then
        print_success "Spotify installato con successo via Flatpak"
        return 0
    fi

    print_error "❌❌❌ Tutti i tentativi di installazione di Spotify sono falliti"
    return 1
}

# Installa applicazioni Flatpak
install_flatpak_apps() {
    setup_flatpak

    # Lista applicazioni Flatpak da installare
    local flatpak_apps=(
        "org.telegram.desktop"
        "org.localsend.localsend_app"
        "com.plexamp.Plexamp"
        "org.upscayl.Upscayl"
        "com.rustdesk.RustDesk"
        "org.freac.freac"
        "org.freefilesync.FreeFileSync"
        "com.discordapp.Discord"
        "io.github.jonmagon.kdiskmark"
        "com.geeks3d.furmark"
        "io.github.wiiznokes.fan-control"
        "org.gnome.EasyTAG"
        "dev.edfloreshz.Tasks"

    )

    # Installa ogni app
    for app in "${flatpak_apps[@]}"; do
        print_msg "Installazione $app via Flatpak"
        if flatpak info "$app" &>/dev/null; then
            print_warn "$app è già installato"
        elif flatpak install flathub "$app" -y; then
            print_success "$app installato con successo"
        else
            print_error "Installazione di $app fallita"
        fi
    done
}

# Installazione file deb
install_deb_packages() {
    print_msg "Installazione pacchetti DEB..."

    # Discord
    install_deb "discord.deb" "https://discord.com/api/download?platform=linux&format=deb"

    # Zoom
    install_deb "zoom.deb" "https://zoom.us/client/latest/zoom_amd64.deb"

    # Obsidian
    install_deb "obsidian.deb" "https://github.com/obsidianmd/obsidian-releases/releases/download/v1.4.16/obsidian_1.4.16_amd64.deb"
}

install_appimage_packages() {
    print_msg "Installazione pacchetti AppImage..."

    # Crea directory per le AppImage se non esiste
    mkdir -p "$HOME/Applications"

    # Chatbox
    install_appimage "chatbox" "https://chatboxai.app/install_chatbox/linux/"

    # ResponsivelyApp
    install_appimage "responsively" "https://github.com/responsively-org/responsively-app-releases/releases/download/v1.16.0/ResponsivelyApp-1.16.0.AppImage"
}

# Funzione generica per installare AppImage
install_appimage() {
    local app_name="$1"
    local download_url="$2"
    local desktop_name="${3:-$app_name}"
    local app_path="$HOME/Applications/${app_name}.AppImage"

    print_msg "Installazione $app_name..."

    # Scarica AppImage
    wget -q --show-progress -O "$app_path" "$download_url"

    # Rendi eseguibile
    chmod +x "$app_path"

    # Estrai icona dall'AppImage (se possibile)
    local icon_path="$HOME/.local/share/icons/${app_name}.png"

    # Estrai l'icona usando --appimage-extract
    tempdir=$(mktemp -d)
    (cd "$tempdir" && "$app_path" --appimage-extract >/dev/null 2>&1)

    # Cerca un'icona nell'AppImage estratta
    if [ -d "$tempdir/squashfs-root" ]; then
        icon_files=$(find "$tempdir/squashfs-root" -name "*.png" -o -name "*.svg" | grep -i -E "icon|logo|${app_name}")
        if [ -n "$icon_files" ]; then
            first_icon=$(echo "$icon_files" | head -n 1)
            cp "$first_icon" "$icon_path"
        else
            # Se non trova un'icona specifica, usa un'icona predefinita
            cp "$tempdir/squashfs-root/.DirIcon" "$icon_path" 2>/dev/null || true
        fi
    fi

    # Se non abbiamo trovato un'icona, usiamo un'icona generica
    if [ ! -f "$icon_path" ]; then
        icon_path="application-x-executable"
    fi

    # Crea file .desktop
    mkdir -p "$HOME/.local/share/applications"
    cat >"$HOME/.local/share/applications/${app_name}.desktop" <<EOF
[Desktop Entry]
Name=${desktop_name^}
Exec=${app_path}
Icon=${icon_path}
Type=Application
Categories=Utility;
Terminal=false
EOF

    # Aggiorna la cache delle applicazioni
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

    # Pulisci i file temporanei
    rm -rf "$tempdir"

    print_success "${app_name^} installato correttamente."
}

# Installazione Reaper
install_reaper() {

    print_msg "Installazione REAPER"
    wget -qO reaper.tar.xz "https://www.reaper.fm/files/6.x/reaper668_linux_x86_64.tar.xz"
    mkdir -p /tmp/reaper && tar -xf reaper.tar.xz -C /tmp/reaper
    sudo /tmp/reaper/reaper_linux_x86_64/install-reaper.sh --install /opt --integrate-desktop
    rm -rf /tmp/reaper reaper.tar.xz

    # Gruppi e PATH
    print_msg "Aggiunta ai gruppi video/audio/input"
    sudo usermod -aG video,audio,input $(whoami)

    echo 'export PATH="$PATH:$HOME/.local/bin"' >>~/.bashrc
}

# Installazione Da Vinci Resolve
install_davinci_resolve() {
    print_msg "Installazione Da Vinci Resolve (Metodo Alternativo)..."

    # Salva lo stato dei privilegi attuali
    local is_sudo=0
    if [ "$EUID" -eq 0 ]; then
        is_sudo=1
        # Se stiamo eseguendo come root, diventa l'utente reale
        local real_user=$(logname 2>/dev/null || echo $SUDO_USER)
        
        if [ -z "$real_user" ]; then
            print_error "Impossibile determinare l'utente reale. Uscita."
            return 1
        fi
        
        print_warn "Passaggio temporaneo alla modalità utente normale..."
        
        # Salva l'utente sudo originale e la home
        SUDO_ORIGINAL_USER="$real_user"
        SUDO_ORIGINAL_HOME=$(eval echo ~$real_user)
        
        # Esegui la parte non-sudo come l'utente reale
        sudo -u "$real_user" bash -c "$(declare -f install_davinci_resolve_as_user); install_davinci_resolve_as_user"
        local result=$?
        
        print_warn "Ripristino modalità sudo..."
        return $result
    else
        # Se non stiamo eseguendo come root, esegui direttamente
        install_davinci_resolve_as_user
        return $?
    fi
}

# Funzione che deve essere eseguita come utente normale
install_davinci_resolve_as_user() {
    print_msg "Avvio installazione DaVinci Resolve come utente normale..."

    # Determina l'utente e la home
    ACTUAL_USER="${USER}"
    USER_HOME="$HOME"
    INSTALL_DIR="$USER_HOME/resolve-install"

    # Crea directory e spostati
    mkdir -p "$INSTALL_DIR" && cd "$INSTALL_DIR" || {
        print_error "Impossibile accedere a $INSTALL_DIR"
        return 1
    }

    # Richiedi link manuale
    print_ask "Incolla il link temporaneo da https://www.blackmagicdesign.com/support/downloads/"
    print_ask "Assicurati di copiare il link diretto al file .zip."
    read -p "Link: " RESOLVE_URL

    # Scarica solo se il file non esiste
    if [ ! -f DaVinci_Resolve.zip ]; then
        wget -O DaVinci_Resolve.zip "$RESOLVE_URL" || {
            print_error "Download fallito. Controlla il link."
            return 1
        }
    else
        print_warn "File DaVinci_Resolve.zip già presente. Skipping download."
    fi

    # Verifica esistenza e decomprimi
    [ -f DaVinci_Resolve.zip ] || {
        print_error "File DaVinci_Resolve.zip non trovato."
        return 1
    }

    unzip -o DaVinci_Resolve.zip || {
        print_error "Errore durante l'estrazione del file ZIP."
        return 1
    }

    # Cerca l'installer
    print_msg "Ricerca dell'installer..."
    INSTALLER=$(find "$INSTALL_DIR" -type f -name "DaVinci_Resolve*.run" | head -1)

    if [ -z "$INSTALLER" ]; then
        print_error "Installer non trovato!"
        return 1

    chmod +x "$INSTALLER" || {
        print_error "Impossibile rendere eseguibile l'installer."
        return 1
    }

    # Esegui l'installer
    print_warn "Avvio dell'installer. Potrebbe essere richiesta la password di amministratore."
    bash "$INSTALLER"

    # Pulizia
    print_msg "Pulizia dei file di installazione..."
    read -rp "Eliminare i file di installazione? (y/n): " clean_choice
    if [[ "$clean_choice" =~ ^[Yy]$ ]]; then
        rm -rf "$INSTALL_DIR"
        print_success "File rimossi."
    else
        print_warn "File mantenuti in $INSTALL_DIR"
    fi

    print_success "Installazione DaVinci Resolve completata."
    return 0
}

# Aggiungi le directory al PATH se non già presenti
update_path() {
    print_msg "Aggiornamento PATH..."

    # Aggiungi ~/.local/bin al PATH se non è già presente
    if ! grep -q "PATH=\"\$HOME/.local/bin:\$PATH\"" ~/.bashrc; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >>~/.bashrc
        print_msg "~/.local/bin aggiunto al PATH in ~/.bashrc"
    fi

    # Applica le modifiche al PATH alla sessione corrente
    export PATH="$HOME/.local/bin:$PATH"

    print_msg "Ricorda di eseguire 'source ~/.bashrc' per applicare le modifiche al PATH nella sessione corrente"
}

# Funzione per ritornare allo script principale
return_to_main() {
    print_msg "Ritornando allo script principale..."
    exit 0
}

# Esecuzione principale
main() {
    print_msg "Installazione Applicazioni Esterne"
    setup_repos
    install_pkgs
    install_whatsapp
    install_spotify
    install_flatpak_apps
    install_deb_packages
    install_appimage
    install_reaper
    install_davinci_resolve
    update_path
    print_warn "Alcuni software potrebbero richiedere il riavvio del sistema per funzionare correttamente."
    sleep 3
    return_to_main
}

# Avvia lo script
main
