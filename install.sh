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

main() {
    echo -e "${BLUE}┌───────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${BLUE}│${RESET}  ${GREEN} Auto Install Linux Script  ${RESET}      ${BLUE}│${RESET}"
    echo -e "${BLUE}│${RESET}  ${CYAN} v1.0 Beta -- By Magnetarman  ${RESET}     ${BLUE}│${RESET}"
    echo -e "${BLUE}└───────────────────────────────────────────────────────────────────┘${RESET}\n"
    print_success "Benvenuto nel programma di installazione!"
    print_warn "Rilevamento del sistema operativo... Attendere 3 secondi."
    sleep 3

    if [ -f /etc/os-release ]; then
        . /etc/os-release

        if [[ "$ID" == "arch" || "$ID_LIKE" == *"arch"* ]]; then
            print_success "Sistema Arch-based rilevato. Avvio di arch.sh..."
            # Ottieni la directory dove si trova lo script originale
            SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

            # Richiama lo script nella sottocartella 'arch'
            bash "$SCRIPT_DIR/arch/setup.sh"

        elif [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
            print_success "Sistema Debian/Ubuntu-based rilevato. Avvio di mint.sh..."
            # Ottieni la directory dove si trova lo script originale
            SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

            # Richiama lo script nella sottocartella 'mint'
            bash "$SCRIPT_DIR/mint/setup.sh"
        else
            print_error "Distribuzione non supportata: $ID"
        fi
    else
        print_error "Impossibile determinare il sistema operativo. File /etc/os-release mancante."
    fi
}

main
