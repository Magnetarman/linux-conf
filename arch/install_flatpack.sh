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
        sudo pacman -Sy --noconfirm flatpak
    else
        print_warn "Flatpak è già installato."
    fi

    print_msg "Configurazione Flathub..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    print_success "Flatpak e Flathub pronti."
    sleep 1
}

setup_snap() {
    print_msg "Configurazione Snap..."

    if ! command_exists snap; then
        print_msg "Snap non è installato. Installazione in corso..."
        if command_exists yay; then
            if [ "$EUID" -eq 0 ]; then
                if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
                    print_warn "Eseguo yay come utente normale ($SUDO_USER) tramite sudo."
                    sudo -u "$SUDO_USER" yay -S --noconfirm snapd || {
                        print_warn "Installazione di Snap saltata."
                        return 1
                    }
                else
                    print_warn "Non è stato possibile determinare l'utente non-root per yay. Installazione Snap saltata."
                    return 1
                fi
            else
                yay -S --noconfirm snapd || {
                    print_warn "Installazione di Snap saltata."
                    return 1
                }
            fi
        else
            print_warn "Gestore AUR (yay) non trovato. Installazione Snap saltata."
            return 1
        fi
        print_success "Snap installato correttamente."
    else
        print_success "Snap è già installato."
    fi

    sudo systemctl enable --now snapd.socket || {
        print_error "Impossibile abilitare/avviare snapd.socket"
        return 1
    }

    if [ "$(systemctl is-active snapd.socket)" != "active" ]; then
        print_warn "Il servizio snapd.socket non risulta attivo."
    else
        print_success "Servizio snapd.socket attivo."
    fi

    [ -e /snap ] || sudo ln -sf /var/lib/snapd/snap /snap 2>/dev/null

    # Aggiungi /snap/bin al PATH se necessario (solo per la sessione corrente)
    if [ -d "/snap/bin" ] && [[ ":$PATH:" != *":/snap/bin:"* ]]; then
        export PATH="$PATH:/snap/bin"
        print_warn "Aggiunto /snap/bin al PATH per la sessione corrente."
    fi

    if ! command_exists snap; then
        print_warn "Il comando 'snap' non è disponibile nella sessione corrente. Potrebbe essere necessario riavviare la shell o la sessione utente."
        print_warn "Se dopo il riavvio il comando 'snap' non funziona, verifica che /snap/bin sia nel PATH."
        return 0
    fi

    if ! snap version &>/dev/null; then
        print_error "Snap non sembra funzionare correttamente dopo l'installazione. Potrebbe essere necessario riavviare la sessione utente."
        return 1
    fi

    print_success "Snap configurato correttamente."
    sleep 1
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
