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
        "org.jdownloader.JDownloader"
        "com.spotify.Client"
        "org.cryptomator.Cryptomator"
        "com.ktechpit.whatsie"

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

    # Local By Flywheel
    install_deb "local-by-flywheel.deb" "https://cdn.localwp.com/releases-stable/9.2.4+6788/local-9.2.4-linux.deb"

    if [ $? -ne 0 ]; then
        print_msg "Tentativo di risoluzione automatica delle dipendenze..."
        sudo apt --fix-broken install -y
        sudo dpkg --configure -a
    fi
}

install_appimage() {
    print_msg "Installazione pacchetti AppImage..."

    # Determina l'utente reale (non root)
    REAL_USER=${SUDO_USER:-$USER}
    REAL_HOME=$(eval echo ~$REAL_USER)

    print_msg "Installazione per utente: $REAL_USER (home: $REAL_HOME)"

    # Crea directory per le AppImage se non esiste
    mkdir -p "$REAL_HOME/Applications"
    chown $REAL_USER:$REAL_USER "$REAL_HOME/Applications" 2>/dev/null || true

    # Lista delle AppImage da installare (nome, URL, nome_desktop_opzionale)
    local apps=(
        "chatbox https://chatboxai.app/install_chatbox/linux/"
        "responsively https://github.com/responsively-org/responsively-app-releases/releases/download/v1.16.0/ResponsivelyApp-1.16.0.AppImage ResponsivelyApp"
    )

    # Installa ogni AppImage
    for app_info in "${apps[@]}"; do
        # Separa i parametri
        read -r app_name download_url desktop_name <<<"$app_info"

        # Verifica che i parametri non siano vuoti
        if [ -z "$app_name" ] || [ -z "$download_url" ]; then
            print_msg "Errore: parametri mancanti per $app_info"
            continue
        fi

        # Se desktop_name non è specificato, usa app_name
        desktop_name="${desktop_name:-$app_name}"

        local app_path="$REAL_HOME/Applications/${app_name}.AppImage"

        print_msg "Installazione $app_name da $download_url..."

        # Scarica AppImage con controllo errori
        if ! wget -q --show-progress -O "$app_path" "$download_url"; then
            print_msg "Errore nel download di $app_name"
            rm -f "$app_path" # Rimuovi file parziale se presente
            continue
        fi

        # Verifica che il file sia stato scaricato correttamente
        if [ ! -f "$app_path" ] || [ ! -s "$app_path" ]; then
            print_msg "Errore: file $app_path non scaricato correttamente"
            rm -f "$app_path"
            continue
        fi

        # Rendi eseguibile e imposta proprietario
        chmod +x "$app_path"
        chown $REAL_USER:$REAL_USER "$app_path" 2>/dev/null || true

        # Genera launcher dall'AppImage
        generate_launcher_from_appimage "$app_path" "$app_name" "$desktop_name" "$REAL_USER" "$REAL_HOME"

        print_success "${app_name^} installato correttamente."
    done
}

# Funzione per generare launcher dall'AppImage
generate_launcher_from_appimage() {
    local app_path="$1"
    local app_name="$2"
    local desktop_name="$3"
    local real_user="$4"
    local real_home="$5"

    print_msg "Generazione launcher per $app_name..."

    # Crea directory temporanea per estrazione
    local tempdir=$(mktemp -d)
    local extracted_desktop=""
    local icon_path=""
    local final_icon_path=""

    # Estrai contenuto AppImage
    if (cd "$tempdir" && "$app_path" --appimage-extract >/dev/null 2>&1); then
        local squashfs_root="$tempdir/squashfs-root"

        # Cerca file .desktop esistente nell'AppImage
        extracted_desktop=$(find "$squashfs_root" -name "*.desktop" -type f | head -n 1)

        # Cerca icona nell'AppImage
        local icon_files=$(find "$squashfs_root" -type f \( -name "*.png" -o -name "*.svg" -o -name "*.xpm" -o -name "*.ico" \) | grep -E "(icon|logo|${app_name})" -i | head -n 1)

        # Se non trova icona specifica, cerca .DirIcon o qualsiasi icona
        if [ -z "$icon_files" ]; then
            icon_files=$(find "$squashfs_root" -name ".DirIcon" -o -name "*.png" | head -n 1)
        fi

        if [ -n "$icon_files" ]; then
            # Copia icona nella directory dell'utente
            mkdir -p "$real_home/.local/share/icons"
            final_icon_path="$real_home/.local/share/icons/${app_name}.png"
            cp "$icon_files" "$final_icon_path" 2>/dev/null || true
            chown $real_user:$real_user "$final_icon_path" 2>/dev/null || true
        fi
    fi

    # Se non è stata trovata un'icona, usa una generica
    if [ -z "$final_icon_path" ] || [ ! -f "$final_icon_path" ]; then
        final_icon_path="application-x-executable"
    fi

    # Genera informazioni per il .desktop
    local exec_line="$app_path"
    local comment_line="$desktop_name AppImage"
    local categories_line="Utility;Development;"

    # Se abbiamo trovato un .desktop esistente, estrai informazioni
    if [ -n "$extracted_desktop" ] && [ -f "$extracted_desktop" ]; then
        print_msg "Trovato file .desktop originale, estraggo informazioni..."

        # Estrai informazioni dal .desktop originale
        local orig_name=$(grep "^Name=" "$extracted_desktop" | head -n 1 | cut -d'=' -f2- | sed 's/^[[:space:]]*//')
        local orig_comment=$(grep "^Comment=" "$extracted_desktop" | head -n 1 | cut -d'=' -f2- | sed 's/^[[:space:]]*//')
        local orig_categories=$(grep "^Categories=" "$extracted_desktop" | head -n 1 | cut -d'=' -f2- | sed 's/^[[:space:]]*//')

        # Usa le informazioni originali se disponibili
        [ -n "$orig_name" ] && desktop_name="$orig_name"
        [ -n "$orig_comment" ] && comment_line="$orig_comment"
        [ -n "$orig_categories" ] && categories_line="$orig_categories"
    fi

    # Crea directory per .desktop files
    mkdir -p "$real_home/.local/share/applications"
    mkdir -p "/usr/share/applications" 2>/dev/null || true

    # Genera file .desktop migliorato
    local desktop_content="[Desktop Entry]
Version=1.0
Type=Application
Name=$desktop_name
Comment=$comment_line
Icon=$final_icon_path
Exec=$exec_line
Categories=$categories_line
Terminal=false
StartupNotify=true
X-AppImage-Version=1.0"

    # Crea launcher nella directory utente
    local user_desktop_file="$real_home/.local/share/applications/${app_name}.desktop"
    echo "$desktop_content" >"$user_desktop_file"
    chmod +x "$user_desktop_file"
    chown $real_user:$real_user "$user_desktop_file" 2>/dev/null || true

    # Crea launcher sul desktop dell'utente
    local desktop_launcher="$real_home/Desktop/${app_name}.desktop"
    echo "$desktop_content" >"$desktop_launcher"
    chmod +x "$desktop_launcher"
    chown $real_user:$real_user "$desktop_launcher" 2>/dev/null || true

    # Prova a copiare anche in /usr/share/applications (per visibilità globale)
    if [ -w "/usr/share/applications" ] || [ "$EUID" -eq 0 ]; then
        echo "$desktop_content" >"/usr/share/applications/${app_name}.desktop" 2>/dev/null || true
    fi

    # Pulisci directory temporanea
    rm -rf "$tempdir"

    # Aggiorna cache del sistema
    update_desktop_cache "$real_user" "$real_home"

    print_msg "Launcher creato: $user_desktop_file"
    print_msg "Icona desktop creata: $desktop_launcher"
}

# Funzione per aggiornare cache desktop
update_desktop_cache() {
    local real_user="$1"
    local real_home="$2"

    print_msg "Aggiornamento cache desktop..."

    # Aggiorna database applicazioni utente
    if command -v update-desktop-database >/dev/null 2>&1; then
        sudo -u "$real_user" update-desktop-database "$real_home/.local/share/applications" 2>/dev/null || true
        update-desktop-database "/usr/share/applications" 2>/dev/null || true
    fi

    # Aggiorna cache icone
    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        sudo -u "$real_user" gtk-update-icon-cache -f -t "$real_home/.local/share/icons" 2>/dev/null || true
        gtk-update-icon-cache -f -t "/usr/share/icons/hicolor" 2>/dev/null || true
    fi

    # Forza aggiornamento menu XDG
    if command -v xdg-desktop-menu >/dev/null 2>&1; then
        sudo -u "$real_user" xdg-desktop-menu forceupdate 2>/dev/null || true
    fi

    # Notifica il sistema di file changes per ambienti desktop moderni
    if command -v dbus-send >/dev/null 2>&1; then
        sudo -u "$real_user" dbus-send --session --dest=org.freedesktop.FileManager1 --type=method_call /org/freedesktop/FileManager1 org.freedesktop.FileManager1.ShowFolders array:string:"file://$real_home/.local/share/applications" string:"" 2>/dev/null || true
    fi

    print_msg "Cache aggiornate. Potrebbe essere necessario logout/login per vedere le modifiche."
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
