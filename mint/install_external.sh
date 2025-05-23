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

install_davinci_resolve() {
    print_msg "Installazione DaVinci Resolve"

    # Identifica la cartella dello script
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    print_msg "Directory dello script: $script_dir"

    # Controlla modalità sudo e riavvia come utente normale se necessario
    if [ "$EUID" -eq 0 ]; then
        print_warn "Rilevata modalità sudo. Avvio sessione temporanea non-sudo per questa funzione..."
        [ -z "$SUDO_USER" ] && {
            print_error "Impossibile determinare l'utente originale. Esci dalla modalità sudo manualmente."
            return 1
        }
        sudo -u "$SUDO_USER" bash -c "$(declare -f install_davinci_resolve print_msg print_warn print_error print_success print_ask); cd '$script_dir'; install_davinci_resolve"
        return $?
    fi

    # Installa wget se necessario
    command -v wget &>/dev/null || {
        print_msg "Installazione di wget..."
        sudo apt-get update && sudo apt-get install -y wget || {
            print_error "Errore nell'installazione di wget"
            return 1
        }
    }

    # Setup directory temporanea
    temp_dir="/tmp/davinci-resolve-install"
    rm -rf "$temp_dir" && mkdir -p "$temp_dir"

    # Opzioni di download
    print_msg "Opzioni di download disponibili:"
    print_msg "1. Download automatico (richiede link diretto al file zip)"
    print_msg "2. Usa file zip già scaricato localmente"
    read -p "Scegli un'opzione (1 o 2): " download_option

    case $download_option in
    1) # Download automatico
        cat <<'EOF'
Per ottenere il link diretto:
1. Vai su: https://www.blackmagicdesign.com/support/downloads/
2. Cerca 'DaVinci Resolve' nella sezione Video Editing
3. Clicca su 'Download Now' per la versione Linux
4. Compila il form di registrazione
5. Dopo aver cliccato 'Download Now', copia il link del download
   (fai clic destro sul pulsante di download e seleziona 'Copia indirizzo link')
EOF
        read -p "Incolla qui il link diretto al download: " download_url
        [ -z "$download_url" ] && {
            print_error "Nessun URL fornito. Installazione annullata."
            rm -rf "$temp_dir"
            return 1
        }

        download_url=$(echo "$download_url" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        zip_filename=$(basename "$download_url" | cut -d'?' -f1)
        [[ ! "$zip_filename" =~ \.zip$ ]] && zip_filename="davinci-resolve.zip"
        zip_path="$temp_dir/$zip_filename"

        print_msg "Download di DaVinci Resolve in corso..."
        print_warn "Questo processo potrebbe richiedere diversi minuti..."
        wget --progress=bar:force:noscroll -O "$zip_path" "$download_url" 2>&1 || {
            print_error "Errore durante il download"
            rm -rf "$temp_dir"
            return 1
        }
        ;;

    2) # File locale
        print_ask "Assicurati di aver già scaricato il file .zip di DaVinci Resolve da:"
        print_ask "https://www.blackmagicdesign.com/support/downloads/"
        read -p "Incolla qui il percorso completo del file .zip: " local_zip_path
        [ -z "$local_zip_path" ] && {
            print_error "Nessun percorso fornito. Installazione annullata."
            rm -rf "$temp_dir"
            return 1
        }

        local_zip_path=$(echo "$local_zip_path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed "s/^['\"]//;s/['\"]$//")
        [ ! -f "$local_zip_path" ] && {
            print_error "File non trovato: $local_zip_path"
            rm -rf "$temp_dir"
            return 1
        }

        zip_filename=$(basename "$local_zip_path")
        zip_path="$temp_dir/$zip_filename"
        print_msg "Copia del file nella directory temporanea..."
        cp "$local_zip_path" "$zip_path" || {
            print_error "Errore nella copia del file"
            rm -rf "$temp_dir"
            return 1
        }
        ;;

    *)
        print_error "Opzione non valida. Installazione annullata."
        rm -rf "$temp_dir"
        return 1
        ;;
    esac

    # Verifica file zip
    [[ ! "$zip_path" =~ \.zip$ ]] && {
        print_warn "Il file fornito non sembra essere un file .zip"
        read -p "Vuoi continuare comunque? (y/n): " continue_anyway
        [[ ! "$continue_anyway" =~ ^[Yy]$ ]] && {
            echo "Installazione annullata."
            rm -rf "$temp_dir"
            return 1
        }
    }

    [ ! -f "$zip_path" ] && {
        print_error "File zip non trovato in $zip_path"
        rm -rf "$temp_dir"
        return 1
    }

    # Verifica integrità e estrazione
    print_msg "Verifica integrità del file zip..."
    unzip -t "$zip_path" >/dev/null 2>&1 || {
        print_error "Il file zip è corrotto o danneggiato"
        rm -rf "$temp_dir"
        return 1
    }

    print_msg "Estrazione del file .zip in corso..."
    unzip -q "$zip_path" -d "$temp_dir" || {
        print_error "Errore nell'estrazione del file .zip"
        rm -rf "$temp_dir"
        return 1
    }
    print_success "Estrazione completata"

    # Debug: mostra contenuto estratto
    print_msg "Debug: Contenuto della directory estratta:"
    find "$temp_dir" -type f -ls

    # Ricerca file .run (ricerca progressiva)
    print_msg "Ricerca del file .run..."
    run_file=$(find "$temp_dir" -name "DaVinci_Resolve*.run" -type f | head -n 1)
    [ -z "$run_file" ] && run_file=$(find "$temp_dir" -name "*.run" -type f | head -n 1)
    [ -z "$run_file" ] && run_file=$(find "$temp_dir" -type f -executable | grep -i davinci | head -n 1)

    [ -z "$run_file" ] && {
        print_error "Nessun file .run o eseguibile trovato nella directory estratta"
        print_msg "Debug: Tutti i file presenti:"
        find "$temp_dir" -type f -ls
        return 1
    }

    print_success "File eseguibile trovato: $(basename "$run_file")"
    [ ! -x "$run_file" ] && {
        print_msg "Rendendo il file eseguibile..."
        chmod +x "$run_file"
    }

    # Verifica e copia script makeresolvedeb.sh
    makeresolvedeb_script="$script_dir/makeresolvedeb.sh"
    [ ! -f "$makeresolvedeb_script" ] && {
        print_error "Script makeresolvedeb.sh non trovato in $script_dir"
        return 1
    }

    print_success "Script makeresolvedeb.sh trovato, copia in directory temporanea..."
    cp "$makeresolvedeb_script" "$temp_dir/" && chmod +x "$temp_dir/makeresolvedeb.sh" || {
        print_error "Errore nella copia dello script makeresolvedeb.sh"
        return 1
    }

    # Creazione e installazione pacchetto .deb
    print_msg "Avvio della creazione del pacchetto .deb..."
    print_warn "Questo processo potrebbe richiedere diversi minuti..."

    original_dir=$(pwd)
    cd "$temp_dir" || {
        print_error "Impossibile entrare nella directory temporanea"
        return 1
    }

    # Usa solo il nome del file .run senza il percorso completo
    run_filename=$(basename "$run_file")
    print_msg "Esecuzione: ./makeresolvedeb.sh $run_filename"

    if ./makeresolvedeb.sh "$run_filename"; then
        print_success "Pacchetto .deb creato con successo"

        deb_file=$(find . -name "*.deb" -type f | head -n 1)
        [ -z "$deb_file" ] && {
            print_error "Pacchetto .deb non generato"
            cd "$original_dir"
            return 1
        }

        print_msg "Installazione del pacchetto .deb: $(basename "$deb_file")"

        if sudo dpkg -i "$deb_file"; then
            print_success "Installazione completata con successo"
        else
            print_error "Errore durante l'installazione. Tentativo di risoluzione delle dipendenze..."
            sudo apt-get install -f -y
            if sudo dpkg -i "$deb_file"; then
                print_success "Installazione completata dopo la risoluzione delle dipendenze"
            else
                print_error "Installazione fallita. Controlla i log per maggiori dettagli."
                cd "$original_dir"
                return 1
            fi
        fi
    else
        print_error "Errore nella creazione del pacchetto .deb"
        cd "$original_dir"
        return 1
    fi

    cd "$original_dir"
    print_success "DaVinci Resolve installato con successo!"
    print_msg "File temporanei mantenuti in: $temp_dir"
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
