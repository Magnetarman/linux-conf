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

# Verifica dell'installazione pip3
install_pip3() {
    print_msg "nstallazione di pip3"
    sudo apt install -y python3-pip

    print_msg "Aggiunta di ~/.local/bin al PATH se non già presente"
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >>~/.bashrc
        source ~/.bashrc
    fi
}

# Installazione di MyBash
install_mybash() {
    print_msg "Installazione e configurazione MyBash..."

    USER_HOME=$(eval echo "~$SUDO_USER")
    gitpath="$USER_HOME/.mybash"

    # Installazione pacchetti necessari
    print_msg "Installazione pacchetti necessari..."
    apt install -y git curl wget unzip fontconfig

    # Clonazione del repository mybash
    print_msg "Clonazione del repository MyBash..."
    if [ -d "$gitpath" ]; then
        print_warn "Directory MyBash esistente. Rimozione in corso..."
        rm -rf "$gitpath"
    fi
    mkdir -p "$USER_HOME/.local/share"
    sudo -u "$SUDO_USER" git clone https://github.com/ChrisTitusTech/mybash.git "$gitpath"

    # Installazione del font Nerd Font
    print_msg "Verifica e installazione del font MesloLGS Nerd Font..."
    FONT_NAME="MesloLGS Nerd Font Mono"
    if fc-list :family | grep -iq "$FONT_NAME"; then
        print_warn "Font '$FONT_NAME' già installato."
    else
        print_msg "Installazione del font '$FONT_NAME'..."
        FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
        FONT_DIR="$USER_HOME/.local/share/fonts"
        TEMP_DIR=$(mktemp -d)
        curl -sSLo "$TEMP_DIR/${FONT_NAME}.zip" "$FONT_URL"
        unzip "$TEMP_DIR/${FONT_NAME}.zip" -d "$TEMP_DIR"
        mkdir -p "$FONT_DIR/$FONT_NAME"
        mv "${TEMP_DIR}"/*.ttf "$FONT_DIR/$FONT_NAME"
        fc-cache -fv
        rm -rf "${TEMP_DIR}"
        print_success "Font '$FONT_NAME' installato con successo."
    fi

    # Installazione di Starship
    print_msg "Installazione di Starship (prompt personalizzato)..."
    if ! curl -sSL https://starship.rs/install.sh | sh -s -- -y; then
        print_error "Si è verificato un errore durante l'installazione di Starship!"
        exit 1
    fi

    # Installazione di FZF
    print_msg "Installazione di FZF (ricerca fuzzy)..."
    if command_exists fzf; then
        print_warn "FZF già installato."
    else
        apt install -y fzf || {
            print_warn "FZF non trovato nei repository. Installazione da git..."
            sudo -u "$SUDO_USER" git clone --depth 1 https://github.com/junegunn/fzf.git "$USER_HOME/.fzf"
            sudo -u "$SUDO_USER" "$USER_HOME/.fzf/install" --all
        }
    fi

    # Installazione di Zoxide
    print_msg "Installazione di Zoxide (navigazione intelligente tra directory)..."
    sudo apt install -y zoxide
    if command_exists zoxide; then
        print_warn "Zoxide già installato."
    else
        if ! curl -sSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
            print_error "Si è verificato un errore durante l'installazione di Zoxide!"
            exit 1
        fi
    fi

    # Collegamento dei file di configurazione
    print_msg "Collegamento dei file di configurazione..."
    OLD_BASHRC="$USER_HOME/.bashrc"
    if [ -e "$OLD_BASHRC" ] && [ ! -e "$USER_HOME/.bashrc.bak" ]; then
        print_warn "Spostamento del vecchio file di configurazione bash in $USER_HOME/.bashrc.bak"
        if ! mv "$OLD_BASHRC" "$USER_HOME/.bashrc.bak"; then
            print_error "Impossibile spostare il vecchio file di configurazione bash!"
            exit 1
        fi
    fi

    print_warn "Collegamento del nuovo file di configurazione bash..."
    ln -svf "$gitpath/.bashrc" "$USER_HOME/.bashrc" || {
        print_error "Impossibile creare il link simbolico per .bashrc"
        exit 1
    }

    # Assicurati che la directory di configurazione esista
    mkdir -p "$USER_HOME/.config"

    ln -svf "$gitpath/starship.toml" "$USER_HOME/.config/starship.toml" || {
        print_error "Impossibile creare il link simbolico per starship.toml"
        exit 1
    }

    print_success "MyBash installato con successo!"
}

# Configurazione di Fastfetch
setup_fastfetch() {
    # Fastfetch da sorgente
    print_msg "Compilazione Fastfetch"
    sudo add-apt-repository -y ppa:fish-shell/release-3
    sudo apt update
    sudo apt install -y fish cmake ninja-build pkg-config libpci-dev libvulkan-dev libwayland-dev libxrandr-dev libxcb-randr0-dev libx11-dev
    git clone https://github.com/fastfetch-cli/fastfetch.git /tmp/fastfetch
    cmake -S /tmp/fastfetch -B /tmp/fastfetch/build -GNinja && ninja -C /tmp/fastfetch/build && sudo ninja -C /tmp/fastfetch/build install
    rm -rf /tmp/fastfetch

    print_msg "Configurazione di Fastfetch..."
    if ! command_exists fastfetch; then
        print_msg "Fastfetch non trovato nei repository standard. Installazione alternativa..."

        # Aggiornamento dipendenze Fastfetch
        print_warn "Aggiornamento dipendenze Fastfetch"
        sudo apt update && sudo apt install -y \
            git cmake build-essential pkg-config \
            libpci-dev libgl1-mesa-dev

        # Clonazione del repository
        print_msg "Clonazione repository Fastfetch..."
        git clone https://github.com/fastfetch-cli/fastfetch.git
        cd fastfetch

        # Creazione directory di build
        print_msg "Compilazione..."
        mkdir -p build && cd build
        cmake ..
        make -j$(nproc)

        # Installazione
        print_msg "Installazione..."
        sudo make install
        cd ../..
    else
        print_warn "Fastfetch è già installato."
    fi

    print_msg "Copia file configurazione Fastfetch..."
    mkdir -p "$HOME/.config/fastfetch"
    curl -sSLo "$HOME/.config/fastfetch/config.jsonc" https://raw.githubusercontent.com/ChrisTitusTech/mybash/main/config.jsonc
    print_success "File di configurazione Fastfetch copiato."

    print_msg "Aggiunta Fastfetch alla shell..."
    if grep -q "fastfetch" "$HOME/.bashrc"; then
        print_warn "Fastfetch è già configurato in .bashrc"
    else
        echo -e "\n# Avvia Fastfetch all'avvio della shell\nfastfetch" >>"$HOME/.bashrc"
        print_success "Fastfetch aggiunto a .bashrc"
    fi
}

# Installazione Font Addizionali (Terminus)
install_additional_fonts() {
    print_msg "Installazione font addizionali (Terminus)..."

    FONT_PACKAGE="xfonts-terminus"

    if dpkg -l | grep -q "$FONT_PACKAGE"; then
        print_warn "Font Terminus già installato."
    else
        print_msg "Installazione del font Terminus in corso..."
        apt install -y $FONT_PACKAGE && print_success "Font Terminus installato con successo." || print_warn "Installazione del font fallita, continuo comunque..."
    fi

    print_msg "Configurazione del font Terminus per la TTY..."
    if [ -f "/etc/default/console-setup" ]; then
        sed -i 's/^FONTFACE=.*/FONTFACE="Terminus"/' /etc/default/console-setup
        sed -i 's/^FONTSIZE=.*/FONTSIZE="16"/' /etc/default/console-setup
        update-initramfs -u
        print_success "Font Terminus configurato per TTY."
    else
        print_warn "File console-setup non trovato, salto configurazione TTY."
    fi
}

# Installazione e configurazione alias utili

install_alias() {
    print_msg "Configurazione alias utili per il sistema..."

    BASHRC_FILE="$HOME/.bashrc"
    ALIASES_FILE="$HOME/.bash_aliases"

    # Verifica se .bashrc carica già .bash_aliases
    if ! grep -q "\.bash_aliases" "$BASHRC_FILE" 2>/dev/null; then
        print_msg "Configurazione di .bashrc per caricare .bash_aliases..."

        # Aggiungi il caricamento di .bash_aliases in .bashrc
        cat >>"$BASHRC_FILE" <<'EOL'

# Carica alias personalizzati se il file esiste
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
EOL
    fi

    # Crea il file .bash_aliases se non esiste
    if [ ! -f "$ALIASES_FILE" ]; then
        touch "$ALIASES_FILE"
        print_msg "Creato file .bash_aliases"
    fi

    # Verifica se gli alias esistono già per evitare duplicati
    if ! grep -q "alias upd=" "$ALIASES_FILE" 2>/dev/null; then
        print_msg "Aggiunta alias per aggiornamento sistema..."
        cat >>"$ALIASES_FILE" <<'EOL'

# Alias per aggiornamento completo sistema
alias upd='flatpak update -y && sudo apt update && sudo apt upgrade -y && sudo apt dist-upgrade -y'
EOL
    fi

    if ! grep -q "alias clean=" "$ALIASES_FILE" 2>/dev/null; then
        print_msg "Aggiunta alias per pulizia sistema..."
        cat >>"$ALIASES_FILE" <<'EOL'

# Alias per pulizia pacchetti inutilizzati
alias clean='flatpak remove --unused -y && sudo apt autoremove -y && sudo apt autoclean'
EOL
    fi

    # Assicurati che il file abbia i permessi corretti
    chmod 644 "$ALIASES_FILE"

    # Ricarica gli alias nel processo corrente
    if [ -f "$ALIASES_FILE" ]; then
        source "$ALIASES_FILE" 2>/dev/null || true
    fi

    print_success "Alias configurati con successo."
}

# Funzione per ritornare allo script principale
return_to_main() {
    print_msg "Ritornando allo script principale..."
    exit 0
}

main() {
    install_pip3
    install_mybash
    setup_fastfetch
    install_additional_fonts
    install_alias
    sleep 2
    print_warn "Riavvia la shell alla fine dello script per vedere i cambiamenti."
    sleep 5
    return_to_main
}
# Avvio dello script
main
