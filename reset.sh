#!/bin/bash

# Script per ripristinare Endeavour OS alle impostazioni di fabbrica
# Questo script deve essere eseguito come root (sudo)

# Colori per il testo
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Funzione per stampare messaggi informativi
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Funzione per stampare avvisi
print_warning() {
    echo -e "${YELLOW}[AVVISO]${NC} $1"
}

# Funzione per stampare errori
print_error() {
    echo -e "${RED}[ERRORE]${NC} $1"
}

# Verifica se lo script è eseguito come root
if [ "$EUID" -ne 0 ]; then
    print_error "Questo script deve essere eseguito come root. Usa: sudo $0"
    exit 1
fi

# Chiedi conferma all'utente
echo -e "${RED}ATTENZIONE: Questo script ripristinerà Endeavour OS alle impostazioni di fabbrica.${NC}"
echo -e "${RED}Tutti i dati utente, le applicazioni installate e le configurazioni personalizzate andranno persi.${NC}"
echo -e "${RED}Assicurati di aver fatto un backup dei tuoi dati importanti prima di procedere.${NC}"
read -p "Sei sicuro di voler continuare? (s/N): " confirm
if [[ "$confirm" != [sS] ]]; then
    print_info "Operazione annullata."
    exit 0
fi

# Parte 1: Backup della lista dei pacchetti nativi (pacchetti base del sistema)
print_info "Creazione di un backup della lista dei pacchetti nativi..."
pacman -Qn > /tmp/pacchetti_nativi.txt

# Parte 2: Backup della lista dei pacchetti esplicitamente installati
print_info "Creazione di un backup della lista dei pacchetti esplicitamente installati..."
pacman -Qe > /tmp/pacchetti_espliciti.txt

# Parte 3: Rimuovere tutti i pacchetti installati dall'utente (non base)
print_info "Rimozione dei pacchetti installati dall'utente..."
# Ottenere la lista dei pacchetti installati dall'utente (non nativi)
pacchetti_utente=$(comm -23 <(pacman -Qeq | sort) <(pacman -Qgq base base-devel gnome | sort))

if [ -n "$pacchetti_utente" ]; then
    print_warning "Rimozione dei seguenti pacchetti installati dall'utente:"
    echo "$pacchetti_utente"
    # Rimuovere i pacchetti installati dall'utente e le loro dipendenze non utilizzate
    pacman -Rns $pacchetti_utente --noconfirm
    print_info "Pacchetti utente rimossi con successo."
else
    print_info "Nessun pacchetto utente da rimuovere."
fi

# Parte 4: Pulizia pacchetti orfani
print_info "Rimozione dei pacchetti orfani..."
orphans=$(pacman -Qtdq)
if [ -n "$orphans" ]; then
    pacman -Rns $orphans --noconfirm
    print_info "Pacchetti orfani rimossi con successo."
else
    print_info "Nessun pacchetto orfano da rimuovere."
fi

# Parte 5: Pulizia delle cache di pacman
print_info "Pulizia della cache dei pacchetti..."
pacman -Scc --noconfirm

# Parte 6: Ripristino delle configurazioni di GNOME
print_info "Ripristino delle configurazioni di GNOME alle impostazioni di fabbrica..."
# Ottenere l'elenco degli utenti non di sistema
non_system_users=$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd)

for user in $non_system_users; do
    user_home=$(getent passwd "$user" | cut -d: -f6)
    
    # Verifica se l'utente esiste ed ha una home directory
    if [ -d "$user_home" ]; then
        print_info "Ripristino delle configurazioni GNOME per l'utente $user..."
        
        # Crea un comando che verrà eseguito come l'utente specifico
        su - "$user" -c "
            # Reset completo delle impostazioni GNOME
            dconf reset -f /
            
            # Rimuovi file di configurazione nascosti nella home
            rm -rf ~/.config/gnome-*
            rm -rf ~/.config/dconf
            rm -rf ~/.local/share/gnome-*
            rm -rf ~/.local/share/applications/*
            rm -rf ~/.cache/*
            
            # Reset delle estensioni GNOME
            rm -rf ~/.local/share/gnome-shell/extensions/*
        "
        
        print_info "Configurazione GNOME ripristinata per l'utente $user."
    fi
done

# Parte 7: Pulizia delle directory temporanee del sistema
print_info "Pulizia delle directory temporanee del sistema..."
rm -rf /tmp/*
rm -rf /var/tmp/*

# Parte 8: Ripristino delle impostazioni di sistema
print_info "Ripristino delle impostazioni di sistema..."
# Reimpostare il prompt del terminale e altre configurazioni di sistema
cp /etc/skel/.bashrc /root/.bashrc
for user in $non_system_users; do
    user_home=$(getent passwd "$user" | cut -d: -f6)
    if [ -d "$user_home" ]; then
        cp /etc/skel/.* "$user_home/" 2>/dev/null || true
        chown -R "$user":"$user" "$user_home"
    fi
done

# Parte 9: Ripristino dei servizi di sistema
print_info "Ripristino dei servizi di sistema alle impostazioni predefinite..."
systemctl set-default graphical.target

# Parte 10: Pulizia dei log di sistema
print_info "Pulizia dei log di sistema..."
journalctl --vacuum-time=1d

print_info "Ripristino ai valori di fabbrica completato con successo!"
print_info "Si consiglia di riavviare il sistema per applicare tutte le modifiche."
read -p "Vuoi riavviare il sistema adesso? (s/N): " reboot_now
if [[ "$reboot_now" == [sS] ]]; then
    print_info "Il sistema verrà riavviato tra 5 secondi..."
    sleep 5
    reboot
else
    print_info "Ricordati di riavviare il sistema manualmente quando è conveniente."
fi

exit 0