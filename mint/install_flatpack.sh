# Colori e messaggi in una sola funzione
_c() { case $1 in info) c="\033[0;34m"; p="[INFO]";; ok) c="\033[0;32m"; p="[✅ SUCCESS]";; warn) c="\033[0;33m"; p="[⚠️ WARNING]";; err) c="\033[0;31m"; p="[❌ ERROR]";; ask) c="\033[0;36m"; p="[🤔 ASK]";; esac; shift; echo -e "${c}${p}\033[0m $*"; }
print_msg()     { _c info "$@"; }
print_success() { _c ok "$@"; }
print_warn()    { _c warn "$@"; }
print_error()   { _c err "$@"; }
print_ask()     { _c ask "$@"; }
command_exists() { command -v "$1" &>/dev/null; }

# Installazione di flatpak e flathub
install_flatpak() {
    if ! command_exists flatpak; then
        print_msg "Installazione di Flatpak..."
    sudo apt-get update -y && sudo apt-get install -y flatpak
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
    sudo apt-get update -y && sudo apt-get install -y snapd || {
            print_warn "Installazione di Snap saltata."
            return 1
        }
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

    if ! snap version &>/dev/null; then
        print_error "Snap non sembra funzionare correttamente dopo l'installazione."
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
