#!/bin/bash
## Wrapper generale per l'installazione automatica di Linux Mint
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

# Colori e messaggi in una sola funzione
_c() { case $1 in info) c="\033[0;34m"; p="[INFO]";; ok) c="\033[0;32m"; p="[✅ SUCCESS]";; warn) c="\033[0;33m"; p="[⚠️ WARNING]";; err) c="\033[0;31m"; p="[❌ ERROR]";; ask) c="\033[0;36m"; p="[🤔 ASK]";; esac; shift; echo -e "${c}${p}\033[0m $*"; }
print_msg()     { _c info "$@"; }
print_success() { _c ok "$@"; }
print_warn()    { _c warn "$@"; }
print_error()   { _c err "$@"; }
print_ask()     { _c ask "$@"; }
command_exists() { command -v "$1" &>/dev/null; }

show_title() {
    clear
    cat <<"EOF"
┌───────────────────────────────────────────────────────────────────┐
│                  Auto Install - Mint Version                      │
│                  v2.1.1 -- By MagnetarMan                         │
└───────────────────────────────────────────────────────────────────┘

EOF

    print_success "Benvenuto nel programma di installazione!"
    print_warn "Inizializzazione script in corso... Attendere 3 secondi."
    sleep 3
}

create_log() {
    # Salva tutto l'output dello script in un file di log nella stessa cartella
    local log_file="$SCRIPT_DIR/auto_install_mint_$(date +%Y%m%d_%H%M%S).log"
    print_warn "Tutto l'output verrà salvato in: $log_file"
    print_warn "Se riscontri errori, invia questo file di log per investigare la problematica."
    for i in 5 4 3 2 1; do
        echo -ne "${YELLOW}Continuo tra $i...${RESET}\r"
        sleep 1
    done
    echo
    # Rilancia lo script reindirizzando stdout e stderr su tee
    if [ -z "$LOGGING_ACTIVE" ]; then
        export LOGGING_ACTIVE=1
        exec &> >(tee "$log_file")
    fi
}

# Utilità
command_exists() { command -v "$1" >/dev/null 2>&1; }

# Directory dello script corrente
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

setup_system() {
    print_msg "Aggiornamento del sistema..."
    apt update -qq && apt upgrade -yqq && print_success "Sistema aggiornato con successo."
    print_msg "Controllo installazione di wget..."
    command_exists wget && print_msg "WGet già installato." || (apt install -yqq wget && print_success "WGet installato con successo.")
}

# Wrapper generico per chiamare script di installazione
call_script() {  # $1=nome_script $2=descrizione $3=success_msg
    print_msg "$2"
    bash "$SCRIPT_DIR/$1"
    print_success "$3"
}

install_flatpack()   { call_script install_flatpack.sh   "Installazione di flatpak e flathub in corso..." "Flatpak e Flathub installati con successo."; }
setup_terminal()     { call_script setup_terminal.sh     "Installazione di MyBash, Starship, FZF, Zoxide, Fastfetch in corso..." "MyBash, Starship, FZF, Zoxide, Fastfetch installati con successo."; }
install_apt()        { call_script install_apt.sh        "Installazione pacchetti in corso..." "Pacchetti installati con successo."; }
install_external()   { call_script install_external.sh   "Installazione pacchetti esterni in corso..." "Pacchetti esterni installati con successo."; }

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

add_keys() {
    print_msg "Ricerca e aggiunta automatica delle chiavi GPG mancanti per i repository APT..."
    local missing_keys keyid url
    # Esegui apt update e cattura le key mancanti
    missing_keys=$(apt update 2>&1 | grep 'NO_PUBKEY' | awk '{print $NF}' | sort -u)
    if [[ -z "$missing_keys" ]]; then
        print_success "Nessuna chiave mancante rilevata."
        return 0
    fi
    for keyid in $missing_keys; do
        print_warn "Aggiungo chiave mancante: $keyid"
        url="https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x${keyid}"
        if curl -fsSL "$url" | gpg --dearmor | sudo tee "/etc/apt/keyrings/${keyid}.gpg" >/dev/null; then
            sudo chmod 644 "/etc/apt/keyrings/${keyid}.gpg"
            print_success "Chiave $keyid aggiunta in /etc/apt/keyrings/"
            print_warn "Aggiorna i file .list per usare: signed-by=/etc/apt/keyrings/${keyid}.gpg"
        else
            print_error "Impossibile scaricare o installare la chiave $keyid"
        fi
    done
    print_msg "Aggiornamento delle sorgenti apt..."
    apt update
    print_success "Aggiornamento completato."
}

show_outro() {
    cat <<"EOF"
┌───────────────────────────────────────────────────────────────────┐
│                  Installazione Completata con Successo!           │
│                  Controlla i log per eventuali errori.            │
|                   v2.1.1 -- By MagnetarMan                        │
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
    create_log       # Crea log di tutto lo script
    setup_system     # Ottimizzazione mirror e aggiornamento sistema
    install_flatpack # installazione di Flatpak e Snap
    setup_terminal   # installazione di MyBash, Starship, FZF, Zoxide, Fastfetch, installazione alias
    install_apt      # installazione pacchetti APT
    install_external # installazione pacchetti esterni AppImage, DEB, Installazioni avanzate
    setup_games      # installazione driver e supporto giochi
    setup_mh         # installazione Prodotti MediaHuman
    install_ollama   # installazione di Ollama
    clean_os         # Pulizia del sistema post installazione
    add_keys         # Aggiunta automatica delle chiavi GPG mancanti per i repository APT
    show_outro       # Mostra informazioni finali
    print_warn "🔧🔧🔧 Pulizia Completa! Riavviare il Sistema! 🔧🔧🔧" # Messaggio di chiusura
    reboot_os        # Riavvio del sistema
}

main
exit 0
