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

    # Verifica Wine
    if ! command_exists wine; then
        print_msg "Wine non trovato. Installazione in corso..."
        sudo apt-get update
        sudo apt-get install -y wine64 || {
            print_error "Errore durante l'installazione di Wine. Impossibile procedere."
            exit 1
        }
    fi

    DOWNLOAD_URL="https://www.mediahuman.com/download/MHAudioConverter-x64.exe"
    DOWNLOAD_PATH="/tmp/MHAudioConverter-x64.exe"
    WINE_PREFIX="$HOME/.wine_mhaudioconverter"
    MENU_DIR="$HOME/.local/share/applications"
    ICON_DIR="$HOME/.local/share/icons/hicolor/128x128/apps"

    # Rilevamento directory Desktop (gestisce anche nomi localizzati)
    DESKTOP_DIR=$(xdg-user-dir DESKTOP)
    if [ -z "$DESKTOP_DIR" ]; then
        # Fallback se xdg-user-dir non è disponibile
        if [ -d "$HOME/Desktop" ]; then
            DESKTOP_DIR="$HOME/Desktop"
        elif [ -d "$HOME/Scrivania" ]; then # Versione italiana
            DESKTOP_DIR="$HOME/Scrivania"
        else
            print_warn "Directory Desktop non trovata. Il lanciatore desktop non sarà creato."
        fi
    fi

    # Creazione delle directory necessarie
    mkdir -p "$WINE_PREFIX" "$MENU_DIR" "$ICON_DIR"

    # Download installer
    print_msg "Download di MH Audio Converter..."
    wget -q --show-progress -O "$DOWNLOAD_PATH" "$DOWNLOAD_URL" || {
        print_error "Download fallito."
        exit 1
    }

    # Installazione con Wine
    print_msg "Esecuzione dell'installer..."
    WINEPREFIX="$WINE_PREFIX" wine "$DOWNLOAD_PATH" /SILENT || {
        print_warn "Installazione manuale richiesta."
        print_ask "Completa l'installazione nella finestra e premi Invio quando hai terminato..."
        read -r
    }

    EXEC_PATH="$WINE_PREFIX/drive_c/Program Files/MediaHuman/Audio Converter/MHAudioConverter.exe"

    if [ ! -f "$EXEC_PATH" ]; then
        print_warn "Ricerca alternativa dell'eseguibile..."
        POSSIBLE_EXEC=$(find "$WINE_PREFIX/drive_c" -name "MHAudioConverter.exe" -type f 2>/dev/null | head -n 1)
        if [ -n "$POSSIBLE_EXEC" ]; then
            EXEC_PATH="$POSSIBLE_EXEC"
            print_msg "Eseguibile trovato: $EXEC_PATH"
        else
            print_error "Eseguibile non trovato."
            exit 1
        fi
    fi

    # Creazione dell'icona
    ICON_PATH="$ICON_DIR/mhaudioconverter.png"
    mkdir -p "$ICON_DIR"
    wget -q -O "$ICON_PATH" "https://www.mediahuman.com/img/logos/audio-converter@2x.webp" || print_warn "Icona non scaricata."

    # Creazione lanciatore nel menu
    print_msg "Creazione del lanciatore nel menu..."
    cat >"$MENU_DIR/mhaudioconverter.desktop" <<EOF
[Desktop Entry]
Version=1.0
Name=MH Audio Converter
Comment=Convertitore audio multimediale
Exec=env WINEPREFIX="$WINE_PREFIX" wine "$EXEC_PATH"
Icon=mhaudioconverter
Type=Application
Categories=AudioVideo;Audio;
Terminal=false
StartupNotify=true
MimeType=audio/mpeg;audio/mp4;audio/flac;audio/ogg;audio/wav;
EOF
    chmod +x "$MENU_DIR/mhaudioconverter.desktop"

    # Aggiornamento del database delle applicazioni e cache delle icone
    print_msg "Aggiornamento della cache del menu delle applicazioni..."
    update-desktop-database "$MENU_DIR" 2>/dev/null || true
    gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor 2>/dev/null || true

    # Forza aggiornamento menu per Linux Mint
    print_msg "Aggiornamento del menu di sistema..."
    if command -v cinnamon-menu-editor >/dev/null 2>&1; then
        # Specifico per Cinnamon (Linux Mint)
        timeout 2s cinnamon-menu-editor >/dev/null 2>&1 || true
    fi

    # Lanciatore sul desktop
    if [ -n "$DESKTOP_DIR" ] && [ -d "$DESKTOP_DIR" ]; then
        print_msg "Creazione del lanciatore sul desktop in: $DESKTOP_DIR"
        cp "$MENU_DIR/mhaudioconverter.desktop" "$DESKTOP_DIR/mhaudioconverter.desktop"
        chmod +x "$DESKTOP_DIR/mhaudioconverter.desktop"
        print_success "Lanciatore creato sul desktop."
    else
        print_warn "Directory Desktop non trovata o non accessibile."
    fi

    # Registra l'applicazione come handler predefinito per alcuni formati audio
    print_msg "Registrazione dei tipi MIME..."
    xdg-mime default mhaudioconverter.desktop audio/mpeg audio/mp4 audio/flac audio/ogg audio/wav 2>/dev/null || true

    # Pulizia
    print_msg "Pulizia dei file temporanei..."
    rm -f "$DOWNLOAD_PATH"

    print_success "Installazione di MH Audio Converter completata!"
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
