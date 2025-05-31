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
    curl -sSLo "$HOME/.config/fastfetch/config.jsonc" https://raw.githubusercontent.com/Magnetarman/linux-conf/refs/heads/V2.0/mint/fastfetch/config.jsonc
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

install_alacritty() {
    print_msg "Installazione di Alacritty..."

    # Verifica se già installato
    if command -v alacritty &>/dev/null; then
        print_warn "Alacritty è già installato."
        return 0
    fi

    # Verifica e installa prerequisiti
    print_msg "Verifica prerequisiti..."
    local prerequisites=(git curl)
    for pkg in "${prerequisites[@]}"; do
        if ! command -v "$pkg" &>/dev/null; then
            print_msg "Installazione di $pkg..."
            sudo apt update && sudo apt install -y "$pkg" || {
                print_error "Errore installazione $pkg!"
                return 1
            }
        fi
    done

    # Installazione Rust
    print_msg "Installazione di Rust..."
    if ! command -v rustc &>/dev/null; then
        print_msg "Rust non trovato, installazione in corso..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || {
            print_error "Errore installazione Rust!"
            return 1
        }
        source ~/.cargo/env
        rustup override set stable && rustup update stable
        print_success "Rust installato e configurato."
    else
        print_warn "Rust è già installato."
        source ~/.cargo/env 2>/dev/null || true
    fi

    # Installazione dipendenze
    print_msg "Installazione delle dipendenze..."
    sudo apt install -y cmake pkg-config libfreetype6-dev libfontconfig1-dev \
        libxcb-xfixes0-dev libxkbcommon-dev python3 scdoc || {
        print_error "Errore installazione dipendenze!"
        return 1
    }
    print_success "Dipendenze installate."

    # Download codice sorgente
    print_msg "Download del codice sorgente di Alacritty..."
    cd ~ || return 1
    [ -d "alacritty" ] && {
        print_warn "Directory alacritty esistente trovata, rimozione..."
        rm -rf alacritty
    }

    git clone https://github.com/alacritty/alacritty.git || {
        print_error "Errore download codice sorgente!"
        return 1
    }
    cd alacritty || return 1
    print_success "Codice sorgente scaricato."

    # Compilazione
    print_msg "Avvio compilazione (questo potrebbe richiedere diversi minuti)..."
    cargo build --release || {
        print_error "Errore durante la compilazione!"
        return 1
    }
    print_success "Compilazione completata."

    # Configurazione terminfo
    print_msg "Configurazione terminfo..."
    if ! infocmp alacritty >/dev/null 2>&1; then
        print_msg "Installazione terminfo per Alacritty..."
        sudo tic -xe alacritty,alacritty-direct extra/alacritty.info
        print_success "Terminfo configurato."
    else
        print_warn "Terminfo già configurato."
    fi

    # Desktop entry
    print_msg "Installazione desktop entry..."
    sudo cp target/release/alacritty /usr/local/bin/
    sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
    sudo desktop-file-install extra/linux/Alacritty.desktop
    sudo update-desktop-database
    print_success "Desktop entry installato."

    # Pagine di manuale
    print_msg "Installazione pagine di manuale..."
    sudo mkdir -p /usr/local/share/man/man{1,5}

    if command -v scdoc &>/dev/null; then
        local man_files=(
            "extra/man/alacritty.1.scd:/usr/local/share/man/man1/alacritty.1.gz"
            "extra/man/alacritty-msg.1.scd:/usr/local/share/man/man1/alacritty-msg.1.gz"
            "extra/man/alacritty.5.scd:/usr/local/share/man/man5/alacritty.5.gz"
            "extra/man/alacritty-bindings.5.scd:/usr/local/share/man/man5/alacritty-bindings.5.gz"
        )

        for man_entry in "${man_files[@]}"; do
            local src_file="${man_entry%:*}"
            local dest_file="${man_entry#*:}"
            [ -f "$src_file" ] && scdoc <"$src_file" | gzip -c | sudo tee "$dest_file" >/dev/null
        done
        print_success "Pagine di manuale installate."
    else
        print_warn "scdoc non disponibile, saltando installazione pagine di manuale."
    fi

    # Completamenti shell per Bash
    print_msg "Installazione completamenti shell per Bash..."
    mkdir -p ~/.bash_completion
    cp extra/completions/alacritty.bash ~/.bash_completion/alacritty

    if ! grep -q "source ~/.bash_completion/alacritty" ~/.bashrc 2>/dev/null; then
        echo "source ~/.bash_completion/alacritty" >>~/.bashrc
        print_success "Completamenti shell configurati."
    else
        print_warn "Completamenti shell già configurati in .bashrc."
    fi

    # Configurazione personalizzata
    print_msg "Configurazione di Alacritty..."
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local CONFIG_SOURCE_DIR="$SCRIPT_DIR/mint/alacritty"
    local CONFIG_TARGET_DIR="$HOME/.config/alacritty"

    if [ -d "$CONFIG_SOURCE_DIR" ]; then
        print_msg "Trovata cartella di configurazione personalizzata."
        mkdir -p "$CONFIG_TARGET_DIR"

        # Backup configurazione esistente
        if [ -d "$CONFIG_TARGET_DIR" ] && [ "$(ls -A "$CONFIG_TARGET_DIR" 2>/dev/null)" ]; then
            local BACKUP_DIR="$CONFIG_TARGET_DIR.backup.$(date +%Y%m%d_%H%M%S)"
            print_warn "Configurazione esistente trovata, creazione backup in: $BACKUP_DIR"
            cp -r "$CONFIG_TARGET_DIR" "$BACKUP_DIR"
        fi

        # Copia file di configurazione
        print_msg "Copia dei file di configurazione..."
        cp -r "$CONFIG_SOURCE_DIR"/* "$CONFIG_TARGET_DIR/" || {
            print_error "Errore durante la copia dei file di configurazione!"
            return 1
        }

        if [ "$(ls -A "$CONFIG_TARGET_DIR" 2>/dev/null)" ]; then
            print_success "File di configurazione copiati con successo."
            print_msg "File copiati in: $CONFIG_TARGET_DIR"
        else
            print_error "Errore durante la copia dei file di configurazione!"
        fi
    else
        print_warn "Cartella di configurazione personalizzata non trovata: $CONFIG_SOURCE_DIR"
        mkdir -p "$CONFIG_TARGET_DIR"
        print_msg "Puoi aggiungere i tuoi file di configurazione in: $CONFIG_TARGET_DIR"
    fi

    # Verifica finale
    print_msg "Verifica installazione..."
    if command -v alacritty &>/dev/null; then
        local ALACRITTY_VERSION=$(alacritty --version)
        print_success "Alacritty installato con successo! | Versione: $ALACRITTY_VERSION"
    else
        print_error "Installazione fallita. Alacritty non è stato trovato nel PATH!"
        return 1
    fi
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
    install_alacritty
    sleep 2
    print_warn "Riavvia la shell alla fine dello script per vedere i cambiamenti."
    sleep 5
    return_to_main
}
# Avvio dello script
main
