#!/bin/bash
# Colori e messaggi in una sola funzione
_c() { case $1 in info) c="\033[0;34m"; p="[INFO]";; ok) c="\033[0;32m"; p="[✅ SUCCESS]";; warn) c="\033[0;33m"; p="[⚠️ WARNING]";; err) c="\033[0;31m"; p="[❌ ERROR]";; ask) c="\033[0;36m"; p="[🤔 ASK]";; esac; shift; echo -e "${c}${p}\033[0m $*"; }
print_msg()     { _c info "$@"; }
print_success() { _c ok "$@"; }
print_warn()    { _c warn "$@"; }
print_error()   { _c err "$@"; }
print_ask()     { _c ask "$@"; }
command_exists() { command -v "$1" &>/dev/null; }

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
            if [ "$EUID" -eq 0 ] && [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
                print_warn "Eseguo yay come utente normale ($SUDO_USER) tramite sudo."
                sudo -u "$SUDO_USER" yay -S --noconfirm snapd || return 1
            else
                yay -S --noconfirm snapd || return 1
            fi
            print_success "Snap installato correttamente."
        else
            print_warn "Gestore AUR (yay) non trovato. Installazione Snap saltata."
            return 1
        fi
    else
        print_success "Snap è già installato."
    fi

    sudo systemctl enable --now snapd.socket || { print_error "Impossibile abilitare/avviare snapd.socket"; return 1; }
    systemctl is-active --quiet snapd.socket && print_success "Servizio snapd.socket attivo." || print_warn "Il servizio snapd.socket non risulta attivo."
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

    snap version &>/dev/null || { print_error "Snap non sembra funzionare correttamente dopo l'installazione. Potrebbe essere necessario riavviare la sessione utente."; return 1; }
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
