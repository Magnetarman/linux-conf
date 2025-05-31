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

# Funzione per verificare se un comando esiste
command_exists() {
    command -v "$1" &>/dev/null
}

# Verifica di dipendenze necessarie
check_dependencies() {
    print_msg "Verifica delle dipendenze necessarie..."

    local missing_deps=()
    for dep in wget gpg apt-get lsb_release; do
        if ! command_exists "$dep"; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_warn "Mancano le seguenti dipendenze: ${missing_deps[*]}"
        print_ask "Vuoi installarle? (s/n)"
        read -r response
        if [[ "$response" =~ ^[Ss]$ ]]; then
            print_msg "Installazione delle dipendenze mancanti..."
            sudo apt-get update
            sudo apt-get install -y "${missing_deps[@]}"
        else
            print_error "Impossibile procedere senza dipendenze necessarie."
            exit 1
        fi
    fi
}

# Installazione MH Youtube to MP3 Converter
install_mp3converter() {
    print_msg "Installazione di MediaHuman YouTube to MP3 Converter..."

    # Verifica dell'architettura del sistema
    ARCH=$(dpkg --print-architecture 2>/dev/null)
    if [ $? -ne 0 ]; then
        # Fallback se dpkg non è disponibile
        ARCH=$(uname -m)
        if [[ "$ARCH" == "i"*"86" ]]; then
            ARCH="i386"
        elif [[ "$ARCH" == "x86_64" ]]; then
            ARCH="amd64"
        fi
    fi
    print_msg "Rilevata architettura: $ARCH"

    if [[ "$ARCH" == "i"*"86" ]] || [ "$ARCH" = "i386" ]; then
        DOWNLOAD_URL="https://www.mediahuman.com/download/YouTubeToMP3.i386.deb"
        print_msg "Utilizzo pacchetto per sistema a 32 bit"
    else
        DOWNLOAD_URL="https://www.mediahuman.com/download/YouTubeToMP3.amd64.deb"
        print_msg "Utilizzo pacchetto per sistema a 64 bit"
    fi

    print_msg "Scaricamento del pacchetto da $DOWNLOAD_URL"
    wget -q -O /tmp/youtube-to-mp3.deb "$DOWNLOAD_URL"
    if [ $? -ne 0 ]; then
        print_error "Errore durante il download del pacchetto"
        print_warn "Proseguo con il resto dello script..."
    else
        print_msg "Installazione del pacchetto"
        sudo dpkg -i /tmp/youtube-to-mp3.deb >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            print_msg "Tentativo di risolvere dipendenze mancanti..."
            sudo apt-get install -f -y >/dev/null 2>&1
            if [ $? -ne 0 ]; then
                print_error "Impossibile risolvere le dipendenze"
                print_warn "Proseguo con il resto dello script..."
            else
                # Secondo tentativo dopo aver risolto le dipendenze
                sudo dpkg -i /tmp/youtube-to-mp3.deb >/dev/null 2>&1
                if [ $? -eq 0 ]; then
                    print_success "Installazione di YouTube to MP3 Converter completata con successo!"
                else
                    print_error "Installazione non riuscita dopo la risoluzione delle dipendenze"
                    print_warn "Proseguo con il resto dello script..."
                fi
            fi
        else
            print_success "Installazione di YouTube to MP3 Converter completata con successo!"
        fi

        print_msg "Pulizia dei file temporanei"
        rm -f /tmp/youtube-to-mp3.deb
    fi
}

install_mhaudioconverter() {
    print_msg "Installazione MH Audio Converter con Wine..."

    # Ottieni il nome utente corrente (non root)
    if [ "$EUID" -eq 0 ]; then
        current_user="${SUDO_USER:-$(logname 2>/dev/null || echo $USER)}"
        user_home="/home/$current_user"
    else
        current_user="$USER"
        user_home="$HOME"
    fi

    DOWNLOAD_URL="https://www.mediahuman.com/download/MHAudioConverter-x64.exe"
    DOWNLOAD_PATH="/tmp/MHAudioConverter-x64.exe"
    WINE_PREFIX="$user_home/.wine"

    # Download installer
    print_msg "Download di MH Audio Converter..."
    wget -q --show-progress -O "$DOWNLOAD_PATH" "$DOWNLOAD_URL" || {
        print_error "Download fallito."
        exit 1
    }

    # Configurazione Wine prefix come utente normale
    print_msg "Configurazione ambiente Wine..."
    if [ "$EUID" -eq 0 ]; then
        # Se siamo root, esegui come utente normale
        sudo -u "$current_user" env WINEPREFIX="$WINE_PREFIX" winecfg /v || {
            print_msg "Configurazione Wine automatica..."
            sudo -u "$current_user" env WINEPREFIX="$WINE_PREFIX" wineboot --init
        }
    else
        # Se siamo già utente normale
        env WINEPREFIX="$WINE_PREFIX" winecfg /v || {
            print_msg "Configurazione Wine automatica..."
            env WINEPREFIX="$WINE_PREFIX" wineboot --init
        }
    fi

    # Installazione con Wine come utente normale
    print_msg "Esecuzione dell'installer..."
    if [ "$EUID" -eq 0 ]; then
        # Esegui come utente normale se siamo root
        sudo -u "$current_user" env WINEPREFIX="$WINE_PREFIX" DISPLAY="$DISPLAY" wine "$DOWNLOAD_PATH" /SILENT 2>/dev/null || {
            print_warn "Installazione silenziosa fallita. Tentativo installazione manuale..."
            sudo -u "$current_user" env WINEPREFIX="$WINE_PREFIX" DISPLAY="$DISPLAY" wine "$DOWNLOAD_PATH" || {
                print_error "Installazione fallita."
                rm -f "$DOWNLOAD_PATH"
                return 1
            }
        }
    else
        # Se siamo già utente normale
        env WINEPREFIX="$WINE_PREFIX" wine "$DOWNLOAD_PATH" /SILENT 2>/dev/null || {
            print_warn "Installazione silenziosa fallita. Tentativo installazione manuale..."
            env WINEPREFIX="$WINE_PREFIX" wine "$DOWNLOAD_PATH" || {
                print_error "Installazione fallita."
                rm -f "$DOWNLOAD_PATH"
                return 1
            }
        }
    fi

    # Verifica che l'installazione sia completata
    executable_path="$WINE_PREFIX/drive_c/Program Files/MediaHuman/Audio Converter/MHAudioConverter.exe"
    if [ ! -f "$executable_path" ]; then
        print_error "L'eseguibile non è stato trovato. Installazione potrebbe essere fallita."
        print_msg "Percorso atteso: $executable_path"
        rm -f "$DOWNLOAD_PATH"
        return 1
    fi

    print_msg "Configurazione del collegamento desktop..."

    # Definisci i percorsi per il file .desktop
    desktop_dir="$user_home/.local/share/applications"
    wine_desktop_dir="$user_home/.local/share/applications/wine/Programs/MediaHuman/Audio Converter"

    # Crea le directory necessarie
    mkdir -p "$desktop_dir"
    mkdir -p "$wine_desktop_dir"

    # Crea il file .desktop corretto
    desktop_file="$desktop_dir/mhaudioconverter.desktop"

    cat >"$desktop_file" <<EOF
[Desktop Entry]
Name=MediaHuman Audio Converter
Comment=Convert audio files between different formats
Exec=env WINEPREFIX="$WINE_PREFIX" wine "$executable_path"
Type=Application
StartupNotify=true
Categories=AudioVideo;Audio;
Icon=audio-x-generic
MimeType=audio/mpeg;audio/x-wav;audio/x-flac;audio/ogg;
StartupWMClass=MHAudioConverter.exe
EOF

    # Imposta i permessi corretti
    chmod +x "$desktop_file"

    # Se siamo root, cambia il proprietario
    if [ "$EUID" -eq 0 ]; then
        chown "$current_user:$current_user" "$desktop_file"
        chown "$current_user:$current_user" "$desktop_dir" 2>/dev/null || true
    fi

    # Copia anche nella directory wine (se esiste un file .desktop originale)
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    desktop_source="$script_dir/mint/MediaHuman Audio Converter.desktop"

    if [ -f "$desktop_source" ]; then
        cp "$desktop_source" "$wine_desktop_dir/" 2>/dev/null || true
        if [ "$EUID" -eq 0 ]; then
            chown -R "$current_user:$current_user" "$wine_desktop_dir" 2>/dev/null || true
        fi
        print_msg "File .desktop originale copiato da: $desktop_source"
    else
        print_warn "File .desktop originale non trovato in: $desktop_source"
    fi
    # Aggiorna il database delle applicazioni
    if command_exists update-desktop-database; then
        if [ "$EUID" -eq 0 ]; then
            sudo -u "$current_user" update-desktop-database "$desktop_dir" 2>/dev/null || true
        else
            update-desktop-database "$desktop_dir" 2>/dev/null || true
        fi
    fi

    # Crea anche un launcher sul desktop se richiesto
    desktop_desktop="$user_home/Desktop/MediaHuman Audio Converter.desktop"
    print_ask "Vuoi creare un collegamento sul desktop? (s/n): "
    read -r create_desktop_link
    if [[ "$create_desktop_link" =~ ^[Ss]$ ]]; then
        cp "$desktop_file" "$desktop_desktop"
        chmod +x "$desktop_desktop"
        if [ "$EUID" -eq 0 ]; then
            chown "$current_user:$current_user" "$desktop_desktop"
        fi
        print_success "Collegamento creato sul desktop!"
    fi

    print_success "Installazione e configurazione completate!"

    # Test del launcher
    print_ask "Vuoi testare il lancio dell'applicazione ora? (s/n): "
    read -r test_launch
    if [[ "$test_launch" =~ ^[Ss]$ ]]; then
        print_msg "Avvio di MH Audio Converter..."
        if [ "$EUID" -eq 0 ]; then
            sudo -u "$current_user" env WINEPREFIX="$WINE_PREFIX" DISPLAY="$DISPLAY" wine "$executable_path" &
        else
            env WINEPREFIX="$WINE_PREFIX" wine "$executable_path" &
        fi
        print_msg "Applicazione avviata in background."
    fi

}
# Funzione principale
main() {
    print_msg "Inizio dell'installazione di MediaHuman Tools..."
    check_dependencies
    install_mp3converter
    install_mhaudioconverter
    return_to_main
}

# Funzione per ritornare allo script principale
return_to_main() {
    print_msg "Ritornando allo script principale..."
    exit 0
}

# Avvio dello script
main
