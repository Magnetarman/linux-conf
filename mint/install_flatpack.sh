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

# Installazione di flatpak e flathub
install_flatpak() {
    if ! command_exists flatpak; then
        print_msg "Installazione di Flatpak..."
        sudo apt update
        sudo apt install -y flatpak
    else
        print_warn "Flatpak è già installato."
    fi

    print_msg "Configurazione Flathub..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    print_success "Flatpak e Flathub pronti."
    sleep 2
}

setup_snap() {
    print_msg "Configurazione Snap..."

    # Verifica se snapd è installato, altrimenti installalo
    if ! command -v snap &>/dev/null; then
        print_msg "Snap non è installato. Installazione in corso..."
        sudo apt-get update
        sudo apt-get install -y snapd || {
            print_error "Installazione di Snap fallita."
            return 1
        }
        print_success "Snap installato correttamente."
    else
        print_success "Snap è già installato."
    fi

    # Assicurati che il demone snap sia attivo e abilitato all'avvio
    sudo systemctl enable snapd.socket || {
        print_error "Impossibile abilitare snapd.socket"
        return 1
    }

    sudo systemctl start snapd.socket || {
        print_error "Impossibile avviare snapd.socket"
        return 1
    }

    # Verifica lo stato del servizio
    snapd_status=$(systemctl is-active snapd.socket)
    if [ "$snapd_status" != "active" ]; then
        print_warning "Il servizio snapd.socket non risulta attivo. Stato: $snapd_status"
    else
        print_success "Servizio snapd.socket attivo."
    fi

    # Crea link simbolico per compatibilità classica snap
    if [ ! -e /snap ]; then
        sudo ln -sf /var/lib/snapd/snap /snap || {
            print_warning "Impossibile creare il link simbolico /snap. Potrebbe non essere necessario su tutte le distribuzioni."
        }
    fi

    # Verifica l'installazione
    if ! snap version &>/dev/null; then
        print_error "Snap non sembra funzionare correttamente dopo l'installazione."
        return 1
    fi

    print_success "Snap configurato correttamente."

    # Aspetta che il servizio sia completamente avviato prima di continuare
    sleep 2
}

# Funzione per ritornare allo script principale
return_to_main() {
    print_msg "Ritornando allo script principale..."
    exit 0
}

# Funzione principale
main() {
    install_flatpak
    setup_snap
    return_to_main
}

# Avvia lo script
main
