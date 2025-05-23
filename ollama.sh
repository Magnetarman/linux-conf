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
print_ask() { echo -e "${CYAN}[❓ ASK]${RESET} $1"; }

# Rilevamento distribuzione
print_msg "Rilevamento del sistema operativo..."

if [ -f /etc/os-release ]; then
  . /etc/os-release

  if [[ "$ID" == "arch" || "$ID_LIKE" == *"arch"* ]]; then
    print_success "Sistema Arch-based rilevato. Avvio di arch.sh..."
    bash arch.sh
  elif [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
    print_success "Sistema Debian/Ubuntu-based rilevato. Avvio di mint.sh..."
    bash mint.sh
  else
    print_error "Distribuzione non supportata: $ID"
    exit 1
  fi
else
  print_error "Impossibile determinare il sistema operativo. File /etc/os-release mancante."
  exit 1
fi

# Chiedi all'utente se vuole avviare Ollama
print_ask "Vuoi avviare il servizio Ollama? (s/n): "
read -r risposta

if [[ "$risposta" =~ ^[Ss]$ ]]; then
  print_msg "Avvio del servizio Ollama..."
  bash ollama.sh
else
  print_msg "Servizio Ollama non avviato. Uscita in corso..."
  sleep 5
  clear
fi
