#!/bin/bash
# Colori e messaggi in una sola funzione
_c() { case $1 in info) c="\033[0;34m"; p="[INFO]";; ok) c="\033[0;32m"; p="[✅ SUCCESS]";; warn) c="\033[0;33m"; p="[⚠️ WARNING]";; err) c="\033[0;31m"; p="[❌ ERROR]";; ask) c="\033[0;36m"; p="[🤔 ASK]";; esac; shift; echo -e "${c}${p}\033[0m $*"; }
print_msg()     { _c info "$@"; }
print_success() { _c ok "$@"; }
print_warn()    { _c warn "$@"; }
print_error()   { _c err "$@"; }
print_ask()     { _c ask "$@"; }
command_exists() { command -v "$1" &>/dev/null; }

# Installazione e configurazione di Bottles (Inseirlo nella sezione Giochi)
install_bottles() {
    print_msg "Installazione/configurazione Bottles..."

    # Installazione Bottles
    flatpak list | grep -q com.usebottles.bottles && print_success "Bottles già installato." || {
        print_msg "Installazione di Bottles...";
        flatpak install -y flathub com.usebottles.bottles || { print_error "Installazione di Bottles fallita."; return 1; };
        print_success "Bottles installato correttamente.";
    }

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
    print_msg "Installazione Heroic Games Launcher..."
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
    grep -q 'export PATH="$PATH:$HOME/.local/bin"' "$HOME/.bashrc" && print_success "PATH già configurato in .bashrc" || {
        echo 'export PATH="$PATH:$HOME/.local/bin"' >>"$HOME/.bashrc"
        print_success "PATH aggiornato in .bashrc"
        print_warn "Per rendere effettive le modifiche, esegui 'source ~/.bashrc' o riavvia il terminale"
    }
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
