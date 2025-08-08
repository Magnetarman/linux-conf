#!/bin/bash


# Colori e messaggi in una sola funzione
_c() { case $1 in info) c="\033[0;34m"; p="[INFO]";; ok) c="\033[0;32m"; p="[✅ SUCCESS]";; warn) c="\033[0;33m"; p="[⚠️ WARNING]";; err) c="\033[0;31m"; p="[❌ ERROR]";; ask) c="\033[0;36m"; p="[🤔 ASK]";; esac; shift; echo -e "${c}${p}\033[0m $*"; }
print_msg()     { _c info "$@"; }
print_success() { _c ok "$@"; }
print_warn()    { _c warn "$@"; }
print_error()   { _c err "$@"; }
print_ask()     { _c ask "$@"; }
check_cmd() { command -v "$1" &>/dev/null || { print_msg "Installazione $1..."; sudo apt-get install -y "$1" || print_error "Impossibile installare $1"; }; }

# Installa un pacchetto DEB con gestione degli errori migliorata
install_deb() {
    local pkg="$1" url="$2" pkg_path
    print_msg "Scarico e installo pacchetto DEB: $pkg"
    [[ "$url" =~ ^https?:// ]] && { print_warn "Download da $url"; wget -O "/tmp/$pkg" "$url" || { print_error "Download fallito per $pkg"; return 1; }; pkg_path="/tmp/$pkg"; } || pkg_path="$url"
    file "$pkg_path" | grep -q "Debian binary package" || { print_error "File non valido per $pkg - non è un pacchetto DEB valido"; return 1; }
    sudo dpkg -i "$pkg_path" && print_success "$pkg installato con successo" || { print_warn "Risoluzione dipendenze per $pkg"; sudo apt-get install -f -y; sudo dpkg -i "$pkg_path" && print_success "$pkg installato con successo dopo risoluzione dipendenze" || { print_error "Installazione di $pkg fallita"; return 1; }; }
    [[ "$url" =~ ^https?:// ]] && rm -f "$pkg_path"
    return 0
}

# Setup dei repository
setup_repos() {
    mkdir -p ~/.local/bin ~/.gnupg; sudo mkdir -p /usr/share/keyrings /etc/apt/keyrings /etc/apt/sources.list.d
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
    for repo in brave vscode chrome onlyoffice enpass github-desktop; do print_msg "Aggiungo repo: $repo"; eval "${repos[$repo]}" || print_error "Errore aggiungendo $repo"; done
    print_warn "Aggiorno apt..."; sudo apt-get update
}

# Installa pacchetti dai repository
install_pkgs() {
    declare -A pkgs=(
        ["brave"]="brave-browser"
        ["vscode"]="code"
        ["chrome"]="google-chrome-stable"
        ["onlyoffice"]="onlyoffice-desktopeditors"
        ["enpass"]="enpass"
        ["github-desktop"]="github-desktop"
    )
    for src in brave vscode chrome onlyoffice enpass github-desktop; do
        print_msg "Installo ${pkgs[$src]}"
        sudo apt-get install -y "${pkgs[$src]}" || print_error "Errore installando ${pkgs[$src]}"
    done
}

# Installa applicazioni Flatpak
install_flatpak_apps() {
    setup_flatpak
    local flatpak_apps=(
        org.telegram.desktop org.localsend.localsend_app com.plexamp.Plexamp org.upscayl.Upscayl com.rustdesk.RustDesk org.freac.freac org.freefilesync.FreeFileSync io.github.jonmagon.kdiskmark com.geeks3d.furmark io.github.wiiznokes.fan-control org.gnome.EasyTAG dev.edfloreshz.Tasks org.jdownloader.JDownloader com.spotify.Client org.cryptomator.Cryptomator com.ktechpit.whatsie io.github.peazip.PeaZip
    )
    for app in "${flatpak_apps[@]}"; do
        flatpak info "$app" &>/dev/null && print_warn "$app è già installato" || (flatpak install flathub "$app" -y && print_success "$app installato con successo" || print_error "Installazione di $app fallita")
    done
}

# Installazione file deb
install_deb_packages() {
    print_msg "Installazione pacchetti DEB..."
    # Pacchetti DEB principali
    local debs=(
        "discord.deb|https://discord.com/api/download?platform=linux&format=deb"
        "zoom.deb|https://zoom.us/client/latest/zoom_amd64.deb"
        "obsidian.deb|https://github.com/obsidianmd/obsidian-releases/releases/download/v1.4.16/obsidian_1.4.16_amd64.deb"
    )
    for d in "${debs[@]}"; do IFS='|' read -r name url <<<"$d"; install_deb "$name" "$url"; done

    # Dipendenze Local by Flywheel
    print_msg "Installazione dipendenze per Local by Flywheel..."
    local deps=(
        "libtinfo5_6.4-2_amd64.deb|http://launchpadlibrarian.net/648013231/libtinfo5_6.4-2_amd64.deb"
        "libncurses5_6.4-2_amd64.deb|http://launchpadlibrarian.net/648013227/libncurses5_6.4-2_amd64.deb"
        "libaio1_0.3.113-4_amd64.deb|http://launchpadlibrarian.net/646633572/libaio1_0.3.113-4_amd64.deb"
    )
    for dep in "${deps[@]}"; do IFS='|' read -r fname furl <<<"$dep"; print_msg "Download e installazione $fname..."; curl -O "$furl" && sudo dpkg -i "$fname"; done
    print_msg "Installazione libnss3-tools..."; sudo apt update; sudo apt install -y libnss3-tools
    rm -f libtinfo5_6.4-2_amd64.deb libncurses5_6.4-2_amd64.deb libaio1_0.3.113-4_amd64.deb
    print_msg "Dipendenze installate. Procedendo con Local by Flywheel..."
    install_deb "local-by-flywheel.deb" "https://cdn.localwp.com/stable/latest/deb"
}

install_appimage() {
    print_msg "Installazione pacchetti AppImage..."
    local REAL_USER=${SUDO_USER:-$USER}
    local REAL_HOME=$(eval echo ~$REAL_USER)
    print_msg "Installazione per utente: $REAL_USER (home: $REAL_HOME)"
    mkdir -p "$REAL_HOME/Applications" && chown $REAL_USER:$REAL_USER "$REAL_HOME/Applications" 2>/dev/null || true
    # Definizione AppImage: nome url [desktop_name]
    local -a apps=(
        "chatbox|https://chatboxai.app/install_chatbox/linux/|"
        "responsively|https://github.com/responsively-org/responsively-app-releases/releases/download/v1.16.0/ResponsivelyApp-1.16.0.AppImage|ResponsivelyApp"
    )
    for app in "${apps[@]}"; do
        IFS='|' read -r name url dname <<<"$app"
        [ -z "$name" ] || [ -z "$url" ] && { print_msg "Errore: parametri mancanti per $app"; continue; }
        dname="${dname:-$name}"
        local path="$REAL_HOME/Applications/${name}.AppImage"
        print_msg "Scarico $name da $url..."
        wget -q --show-progress -O "$path" "$url" || { print_msg "Errore download $name"; rm -f "$path"; continue; }
        [ ! -s "$path" ] && { print_msg "Errore: file $path non scaricato correttamente"; rm -f "$path"; continue; }
        chmod +x "$path" && chown $REAL_USER:$REAL_USER "$path" 2>/dev/null || true
        generate_launcher_from_appimage "$path" "$name" "$dname" "$REAL_USER" "$REAL_HOME"
        print_success "${name^} installato correttamente."
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
    local tempdir=$(mktemp -d) squashfs_root extracted_desktop final_icon_path
    if (cd "$tempdir" && "$app_path" --appimage-extract >/dev/null 2>&1); then
        squashfs_root="$tempdir/squashfs-root"
        extracted_desktop=$(find "$squashfs_root" -name "*.desktop" -type f | head -n 1)
        final_icon_path=$(find "$squashfs_root" -type f \( -name "*.png" -o -name "*.svg" -o -name "*.xpm" -o -name "*.ico" \) | grep -E "(icon|logo|${app_name})" -i | head -n 1)
        [ -z "$final_icon_path" ] && final_icon_path=$(find "$squashfs_root" -name ".DirIcon" -o -name "*.png" | head -n 1)
        if [ -n "$final_icon_path" ]; then
            mkdir -p "$real_home/.local/share/icons"
            cp "$final_icon_path" "$real_home/.local/share/icons/${app_name}.png" 2>/dev/null && chown $real_user:$real_user "$real_home/.local/share/icons/${app_name}.png" 2>/dev/null || true
            final_icon_path="$real_home/.local/share/icons/${app_name}.png"
        fi
    fi
    [ -z "$final_icon_path" ] || [ ! -f "$final_icon_path" ] && final_icon_path="application-x-executable"
    local exec_line="$app_path"
    local comment_line="$desktop_name AppImage"
    local categories_line="Utility;Development;"
    if [ -n "$extracted_desktop" ] && [ -f "$extracted_desktop" ]; then
        print_msg "Trovato file .desktop originale, estraggo informazioni..."
        local orig_name orig_comment orig_categories
        orig_name=$(grep "^Name=" "$extracted_desktop" | head -n 1 | cut -d'=' -f2- | sed 's/^[[:space:]]*//')
        orig_comment=$(grep "^Comment=" "$extracted_desktop" | head -n 1 | cut -d'=' -f2- | sed 's/^[[:space:]]*//')
        orig_categories=$(grep "^Categories=" "$extracted_desktop" | head -n 1 | cut -d'=' -f2- | sed 's/^[[:space:]]*//')
        [ -n "$orig_name" ] && desktop_name="$orig_name"
        [ -n "$orig_comment" ] && comment_line="$orig_comment"
        [ -n "$orig_categories" ] && categories_line="$orig_categories"
    fi
    mkdir -p "$real_home/.local/share/applications" "$real_home/Desktop"
    mkdir -p "/usr/share/applications" 2>/dev/null || true

    # Genera file .desktop migliorato
    local desktop_content="[Desktop Entry]
Name=${desktop_name}
Comment=${comment_line}
Exec=${exec_line}
Icon=${final_icon_path}
Terminal=false
Type=Application
Categories=${categories_line}
"
    local user_desktop_file="$real_home/.local/share/applications/${app_name}.desktop"
    echo "$desktop_content" >"$user_desktop_file" && chmod +x "$user_desktop_file" && chown $real_user:$real_user "$user_desktop_file" 2>/dev/null || true
    local desktop_launcher="$real_home/Desktop/${app_name}.desktop"
    echo "$desktop_content" >"$desktop_launcher" && chmod +x "$desktop_launcher" && chown $real_user:$real_user "$desktop_launcher" 2>/dev/null || true
    ([ -w "/usr/share/applications" ] || [ "$EUID" -eq 0 ]) && echo "$desktop_content" >"/usr/share/applications/${app_name}.desktop" 2>/dev/null || true
    rm -rf "$tempdir"
    update_desktop_cache "$real_user" "$real_home"
    print_msg "Launcher creato: $user_desktop_file"
    print_msg "Icona desktop creata: $desktop_launcher"
}

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
    install_davinci_resolve
    update_path
    print_warn "Alcuni software potrebbero richiedere il riavvio del sistema per funzionare correttamente."
    sleep 3
    return_to_main
}

# Avvia lo script
main
