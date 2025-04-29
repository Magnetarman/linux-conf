#!/bin/sh -e

# Ottiene la directory in cui si trova questo script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Controlla se common-script.sh esiste nella stessa directory
if [ ! -f "$SCRIPT_DIR/common-script.sh" ]; then
    echo "common-script.sh non trovato in $SCRIPT_DIR"
    exit 1
fi

# Include common-script.sh dalla stessa directory
. "$SCRIPT_DIR/common-script.sh"

installBottles() {
    if ! command_exists com.usebottles.bottles; then
        printf "%b\n" "${YELLOW}Installing Bottles...${RC}"
        flatpak install -y flathub com.usebottles.bottles
    else
        printf "%b\n" "${GREEN}Bottles is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkFlatpak
installBottles
