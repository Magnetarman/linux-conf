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

    # Download installer
    print_msg "Download di MH Audio Converter..."
    wget -q --show-progress -O "$DOWNLOAD_PATH" "$DOWNLOAD_URL" || {
        print_error "Download fallito."
        exit 1
    }

    # Installazione con Wine
    print_msg "Esecuzione dell'installer..."
    wine "$DOWNLOAD_PATH" /SILENT || {
        print_warn "Installazione manuale richiesta."
        print_ask "Completa l'installazione nella finestra e premi Invio quando hai terminato..."
        read -r
    }

    # Una volta completata l'installazione, copia il file .desktop
    print_msg "Configurazione del collegamento desktop..."

    # Ottieni il nome utente corrente
    current_user=$(whoami)

    # Definisci il percorso di destinazione
    dest_path="/home/$current_user/.local/share/applications/wine/Programs/MediaHuman/Audio Converter"

    # Crea tutte le cartelle necessarie se non esistono
    mkdir -p "$dest_path"

    # Verifica se il file .desktop esiste nella cartella corrente
    if [ -f "MediaHuman Audio Converter.desktop" ]; then
        # Copia il file .desktop nel percorso di destinazione
        cp "MediaHuman Audio Converter.desktop" "$dest_path/"

        if [ $? -eq 0 ]; then
            print_success "File .desktop copiato con successo in $dest_path/"
        else
            print_error "Errore durante la copia del file .desktop"
            return 1
        fi
    else
        print_error "Attenzione: File 'MediaHuman Audio Converter.desktop' non trovato nella cartella corrente"
        return 1
    fi

    print_success "Installazione e configurazione completate!"

    # Pulizia
    rm -f "$DOWNLOAD_PATH"
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
