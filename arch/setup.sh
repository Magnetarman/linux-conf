#!/bin/bash
## Wrapper generale per l'installazione automatica di Arch Linux
# Verifica permessi di root
if [ "$(id -u)" != "0" ]; then
    echo "⚠️  Questo script richiede i permessi di amministratore."
    echo "Riavvio con sudo..."
    sudo "$0" "$@"
    exit $?
fi

# Mantieni sudo attivo per tutta la durata dello script
sudo -v
while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
done 2>/dev/null &

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

show_title() {
    clear
    cat <<"EOF"
┌───────────────────────────────────────────────────────────────────┐
│                  Auto Install - Arch Version                      │
│                  v1.0.0 Beta -- By MagnetarMan                    │
└───────────────────────────────────────────────────────────────────┘

EOF

    print_success "Benvenuto nel programma di installazione!"
    print_warn "Inizializzazione script in corso... Attendere 3 secondi."
    sleep 3
}

# Utilità
command_exists() { command -v "$1" >/dev/null 2>&1; }

# Directory dello script corrente
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

setup_system() {
    print_msg "Aggiornamento del sistema..."
    pacman -Syu --noconfirm && print_success "Sistema aggiornato con successo."

    # Aggiornamento e installazione di wget se non presente
    print_msg "Controllo installazione di wget..."
    if ! command_exists wget; then
        pacman -S --noconfirm wget && print_success "WGet installato con successo."
    else
        print_msg "WGet già installato."
    fi
}

# Installazione di flatpak e flathub
install_flatpack() {
    print_msg "Installazione di flatpak e flathub in corso..."
    bash "$SCRIPT_DIR/install_flatpack.sh"
    print_success "Flatpak e Flathub installati con successo."
}

# Installazione di MyBash, Starship, FZF, Zoxide, Fastfetch
setup_terminal() {
    print_msg "Installazione di MyBash, Starship, FZF, Zoxide, Fastfetch in corso..."
    bash "$SCRIPT_DIR/setup_terminal.sh"
    print_success "MyBash, Starship, FZF, Zoxide, Fastfetch installati con successo."
}

# Installazione Pacchetti APT
install_apt() {
    print_msg "Installazione pacchetti in corso..."
    bash "$SCRIPT_DIR/install_apt.sh"
    print_success "Pacchetti installati con successo."
}

# Installazione Pacchetti Esterni
install_external() {
    print_msg "Installazione pacchetti esterni in corso..."
    bash "$SCRIPT_DIR/install_external.sh"
    print_success "Pacchetti esterni installati con successo."
}

# Installazione Supporto Giochi
setup_games() {
    print_msg "Installazione Driver e Supporto Giochi in corso..."
    bash "$SCRIPT_DIR/setup_games.sh"
    print_success "Giochi installati con successo."
}

# Installazione Prodotti MediaHuman
setup_mh() {
    print_msg "Installazione Prodotti MediaHuman in corso..."
    bash "$SCRIPT_DIR/setup_mh.sh"
    print_success "Prodotti MediaHuman installati con successo."
}

# Installazione e Configurazione Ollama
install_ollama() {
    print_msg "Installazione Ollama..."

    # Verifica dipendenze
    if ! command_exists curl; then
        apt install -yqq curl
    fi

    print_msg "Scarico lo script di installazione di Ollama..."
    curl -fsSL https://ollama.com/install.sh | bash

    MODELS=("llama3" "mistral" "gemma" "codellama" "llava" "phi" "Nessun modello")

    if ! command_exists ollama; then
        print_error "Installazione di Ollama fallita."
        return 1
    fi
    print_success "Ollama installato correttamente."

    print_ask "Scegli un modello da installare:"
    select MODEL in "${MODELS[@]}"; do
        if [[ -n "$MODEL" ]]; then
            if [[ "$MODEL" == "Nessun modello" ]]; then
                print_warn "ATTENZIONE !!! - Ollama non funziona senza un modello scaricato"
                MODEL=""
            else
                print_success "Hai selezionato il modello: $MODEL"
            fi
            break
        else
            print_error "Selezione non valida."
        fi
    done

    print_msg "Avvio del servizio ollama..."
    systemctl enable --now ollama.service

    if systemctl is-active --quiet ollama; then
        print_success "Servizio ollama attivo."
        if [[ -n "$MODEL" ]]; then
            if ! ollama list | grep -q "^$MODEL[[:space:]]"; then
                print_msg "Scarico il modello '$MODEL'..."
                ollama pull "$MODEL"
            else
                print_warn "Il modello '$MODEL' è già installato. Salto il download."
            fi
        fi
    else
        print_error "Errore nell'avvio del servizio ollama."
        return 1
    fi
}

# Pulizia del Sistema post installazione
clean_os() {
    print_msg "Pulizia pacchetti inutilizzati..."

    # Rimuovi LibreOffice e pacchetti correlati solo se presenti
    if dpkg -l | grep -q 'libreoffice'; then
        print_msg "Rimuovo LibreOffice e tutti i pacchetti correlati con purge..."
        apt purge -y 'libreoffice*'
    fi

    print_msg "Rimozione pacchetti non necessari..."
    apt autoremove -y --purge

    print_msg "Pulizia cache apt..."
    apt clean

    print_msg "Pulizia dei file temporanei..."
    rm -rf /var/tmp/*

    # Pulisci i log solo se journalctl è disponibile
    if command_exists journalctl; then
        journalctl --vacuum-time=7d
    fi

    print_success "Aggiornamento e pulizia completati!"
}

show_outro() {
    cat <<"EOF"
┌───────────────────────────────────────────────────────────────────┐
│                  Installazione Completata con Successo!           │
│                  Controlla i log per eventuali errori.            │
|                   v1.0.0 Beta -- By MagnetarMan                   │
└───────────────────────────────────────────────────────────────────┘   
EOF

}

# Funzione riavvio OS
reboot_os() {
    print_ask "Il sistema richiede un riavvio per completare l'installazione. Vuoi riavviare ora? (y/n)"
    read -rp "Riavviare ? (y/n): " REBOOT_CHOICE
    if [[ "$REBOOT_CHOICE" =~ ^[Yy]$ ]]; then
        print_warn "Riavvio programmato tra 10 secondi. Premi Ctrl+C per annullare."
        for ((i = 10; i > 0; i--)); do
            echo -ne "${YELLOW}Riavvio in $i secondi...${RESET}\r"
            sleep 1
        done
        echo
        print_success "Riavvio in corso..."
        reboot
    else
        print_error "Riavvio annullato. E' consigliabile riavviare il sistema prima dell'utilizzo."
    fi
}

# Funzione principale Script
main() {
    show_title       # Show Titolo Script
    setup_system     # Ottimizzazione mirror e aggiornamento sistema
    install_flatpack # installazione di Flatpak e Snap
    setup_terminal   # installazione di MyBash, Starship, FZF, Zoxide, Fastfetch, installazione alias
    install_apt      # installazione pacchetti APT
    install_external # installazione pacchetti esterni AppImage, DEB, Installazioni avanzate
    setup_games      # installazione driver e supporto giochi
    setup_mh         # installazione Prodotti MediaHuman
    install_ollama   # installazione di Ollama
    clean_os         # Pulizia del sistema post installazione
    show_outro       # Mostra informazioni finali
    print_warn "🔧🔧🔧 Pulizia Completa! Riavviare il Sistema! 🔧🔧🔧"
    reboot_os
}

main
exit 0
