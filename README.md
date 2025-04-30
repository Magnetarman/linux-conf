# 🚀 Arch Linux Setup Automatico

![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)

Script di configurazione automatica per sistemi basati su Arch Linux (come EndeavourOS). Questo script installa e configura una selezione di applicazioni e strumenti comunemente utilizzati, ottimizza le impostazioni di sistema e configura i mirror per prestazioni ottimali.

## 📋 Funzionalità

- ✅ Ottimizzazione dei mirror per Italia, Germania e Francia
- ✅ Aggiornamento completo del sistema
- ✅ Installazione e configurazione di yay (gestore pacchetti AUR)
- ✅ Installazione di Plexamp come AppImage
- ✅ Installazione di Ollama per AI locale
- ✅ Installazione di Chatbox Community edition per interagire con ollama
- ✅ Installazione e configurazione di Temi e Font addizionali per il terminale
- ✅ Installazione di una vasta gamma di applicazioni comuni:
  - Browser (Firefox, Brave, Chrome, Edge)
  - Strumenti di produttività (VSCode, OnlyOffice, Obsidian)
  - Media player e editor (VLC, Handbrake, Reaper, MKVToolnix)
  - Client di messaggistica (Discord, Telegram, WhatsApp)
  - Strumenti di sistema e utilità
- ✅ Pulizia automatica del sistema dopo l'installazione

## 🔧 Prerequisiti

- Sistema operativo basato su Arch Linux (come EndeavourOS, Manjaro, ecc.)
- Connessione internet
- Privilegi di amministratore (sudo)

## ⚡ Installazione rapida

```bash
git clone https://github.com/Magnetarman/linux-conf.git
cd linux-conf
chmod +x install.sh
./install.sh
```

## 📦 Pacchetti installati

### Pacchetti di sistema

- reflector (ottimizzazione mirror)
- base-devel (strumenti di compilazione)
- ffmpeg
- python-pip
- tk

### Browser

- Firefox
- Brave
- Google Chrome
- Microsoft Edge

### Produttività e Ufficio

- Visual Studio Code
- OnlyOffice
- Obsidian
- GitHub Desktop

### Media e Intrattenimento

- Plexamp
- VLC
- Spotify
- Reaper (DAW)
- Handbrake
- Media Human YouTube-to-MP3
- Media Human Audio Converter (via Wine)
- MP3tag
- MKVToolnix-GUI
- Freac
- OBS Studio
- Upscayl
- Da Vinci Resolve (free Version)

### Comunicazione

- Discord
- Telegram Desktop
- WhatsApp Desktop
- Thunderbird
- Zoom App

### Gaming

- Steam
- Heroic Game Launcher
- Legendary (Epic Games)

### Strumenti e Utilità

- p7zip (e GUI)
- WinSCP
- RustDesk
- LocalSend
- Enpass
- Wine
- Bottles
- qBittorrent
- JDownloader2
- FreeFileSync
- Media Info
- Responsively
- <del>Google Calendar Widget</del> (Scrica una repo da 40GB, qualcosa non quadra)
- Baobab (analizzatore di spazio su disco)
- Fastfetch
- HDSentinel
- Fancontrol-GUI (tramite script addizionale)
- Piper (configurazione mouse)
- Simplescan (scansione)
- My Bash

### AI e ML

- Ollama

## 🔄 Manutenzione del sistema

Lo script esegue automaticamente diverse operazioni di manutenzione alla fine dell'installazione:

- Rimozione di pacchetti orfani
- Pulizia della cache di pacman
- Pulizia della cache di yay
- Rimozione dei file temporanei
- Ottimizzazione dei log di sistema

## 🛠️ Personalizzazione

Puoi modificare lo script per aggiungere o rimuovere pacchetti in base alle tue esigenze. Per aggiungere un nuovo pacchetto, trova la sezione appropriata nel file `install.sh` e aggiungi il nome del pacchetto all'elenco.

```bash
# Esempio: aggiungere un nuovo pacchetto
yay -S --needed --noconfirm \
    pacchetto-esistente \
    nuovo-pacchetto \
    altro-pacchetto
```

## ⚠️ Note

- Lo script utilizza i mirror di Italia, Germania e Francia. Se ti trovi in un'altra regione, modifica il comando `reflector`.
- Alcuni pacchetti AUR potrebbero richiedere input manuale durante l'installazione, nonostante l'opzione `--noconfirm`.
- Assicurati di avere abbastanza spazio su disco (>10 GB consigliati) prima di eseguire lo script.

## 🤝 Contribuire

Sentiti libero di:

1. Fork del repository
2. Creare un branch per le tue modifiche (`git checkout -b feature/nuova-funzionalita`)
3. Commit delle modifiche (`git commit -am 'Aggiunta nuova funzionalità'`)
4. Push al branch (`git push origin feature/nuova-funzionalita`)
5. Creare una Pull Request

## 📜 Licenza

Questo progetto è distribuito con licenza MIT. Vedi il file `LICENSE` per maggiori dettagli.

---

❤️ Se trovi questo progetto utile, considera di lasciare una stella
