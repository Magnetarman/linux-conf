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

# Installazione e configurazione di Bottles (Inseirlo nella sezione Giochi)
install_bottles() {
    print_msg "Inizio installazione e configurazione di Bottles..."

    # Installazione Bottles
    if flatpak list | grep -q com.usebottles.bottles; then
        print_success "Bottles è già installato. Nessuna azione necessaria."
    else
        print_msg "Installazione di Bottles in corso..."
        flatpak install -y flathub com.usebottles.bottles || {
            print_error "Installazione di Bottles fallita."
            return 1
        }
        print_success "Bottles installato correttamente."
    fi

    # Creazione collegamento nel menu
    local desktop_file="$HOME/.local/share/applications/bottles.desktop"
    mkdir -p "$(dirname "$desktop_file")"

    cat >"$desktop_file" <<EOF
[Desktop Entry]
Name=Bottles
Comment=Run Windows software on Linux using Bottles
Exec=flatpak run com.usebottles.bottles
Icon=com.usebottles.bottles
Terminal=false
Type=Application
Categories=Utility;Wine;
EOF

    print_success "Voce del menu creata per Bottles: $desktop_file"
}

install_heroic() {
    # Installazione Heroic Games Launcher
    print_msg "Installazione di Heroic Games Launcher in corso..."
    if flatpak list | grep -q com.heroicgameslauncher.hgl; then
        print_success "Heroic Games Launcher è già installato."
    else
        flatpak install -y flathub com.heroicgameslauncher.hgl || {
            print_error "Installazione di Heroic Games Launcher fallita."
            return 1
        }
        print_success "Heroic Games Launcher installato correttamente."
    fi

    # Gruppi e PATH
    print_msg "Aggiunta ai gruppi video/audio/input"
    sudo usermod -aG video,audio,input "$(whoami)" || {
        print_error "Aggiunta ai gruppi fallita. Verifica che sudo sia installato e che tu abbia i permessi necessari."
        print_warn "Puoi aggiungere manualmente l'utente ai gruppi con 'sudo usermod -aG video,audio,input $USER'"
    }

    # Aggiungiamo il PATH solo se non è già presente
    if ! grep -q 'export PATH=\"\$PATH:\$HOME/.local/bin\"' "$HOME/.bashrc"; then
        echo 'export PATH="$PATH:$HOME/.local/bin"' >>"$HOME/.bashrc"
        print_success "PATH aggiornato in .bashrc"
        print_warn "Per rendere effettive le modifiche al PATH, esegui 'source ~/.bashrc' o riavvia il terminale"
    else
        print_success "Il PATH è già configurato correttamente in .bashrc"
    fi
}

# Funzione per ritornare allo script principale
return_to_main() {
    print_msg "Ritornando allo script principale..."
    exit 0
}

# Funzione principale
main() {
    install_bottles
    install_heroic
    return_to_main
}

# Avvia lo script
main
