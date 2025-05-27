# 🤖 Auto Install Linux Script 🤖

![Linx Mint](https://img.shields.io/badge/Linux_Mint-92B662?style=for-the-badge&logo=linux-mint&logoColor=white)
![Arch-Linux](https://img.shields.io/badge/Arch_linux-1793d1?style=for-the-badge&logo=Arch-linux&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-2b2b2b?style=for-the-badge&logo=gnu-bash&logoColor=white)

Script di configurazione automatica per sistemi basati su Ubuntu (come Linux Mint, Kubuntu ecc.) ed Arch Linux (come Endeavouros). Questo script installa e configura una selezione di applicazioni e strumenti comunemente utilizzati, ottimizza le impostazioni di sistema e configura i mirror per prestazioni ottimali.

**ATTENZIONE** - Lo script rileva automaticamente la tua distro linux e si configura di conseguenza.

> [!Note]
> La versione 2.0 è in **sviluppo attivo**.
>
> Lo script per Linux Mint è in fase **Beta** per il testing.
>
> Lo script per Arch linux è in fase **Alpha** non pubblico.

## 📋 Funzionalità

- ✅ Aggiornamento completo del sistema
- ✅ Installazione di Ollama per AI locale
- ✅ Installazione di Chatbox Community edition per interagire con ollama
- ✅ Installazione e configurazione di Temi e Font addizionali per il terminale
- ✅ Installazione di una vasta gamma di applicazioni comuni:
  - Browser (Firefox, Brave, Chrome)
  - Strumenti di produttività (VSCode, OnlyOffice, Obsidian)
  - Media player e editor (VLC, Handbrake, Reaper, MKVToolnix, Plexamp)
  - Client di messaggistica (Discord, Telegram)
  - Strumenti di sistema e utilità
- ✅ Pulizia automatica del sistema dopo l'installazione

## 🔧 Prerequisiti

- Sistema operativo basato su Ubuntu (come Linux Mint, Kubuntu ecc.)
- Connessione internet
- Privilegi di amministratore (sudo)

## ⚡ Avvio Script

```bash
git clone https://github.com/Magnetarman/linux-conf.git
cd linux-conf
chmod +x run.sh
./run.sh
```

## 📦 Pacchetti installati

### Browser

- Firefox
- Brave
- Google Chrome

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
- EasyTAG
- MKVToolnix-GUI
- Freac
- OBS Studio
- Upscayl
- Jdownloader 2
- Da Vinci Resolve (free Version) Thanks with ❤️ to [Daniel Tufvesson](https://www.danieltufvesson.com/makeresolvedeb)

### Comunicazione

- Discord
- Telegram Desktop
- Thunderbird
- Zoom App

### Gaming

- Steam
- Heroic Game Launcher

### Strumenti e Utilità

- p7zip (e GUI)
- Filezilla
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
- Baobab (analizzatore di spazio su disco)
- Fastfetch
- Fancontrol-GUI
- Piper (configurazione mouse)
- Simplescan (scansione)
- My Bash
- Timeshift

### AI e ML

- Ollama

## 🔄 Manutenzione del sistema

Lo script esegue automaticamente diverse operazioni di manutenzione alla fine dell'installazione:

- Rimozione di pacchetti orfani
- Pulizia della cache pacchetti
- Rimozione dei file temporanei

## ⚠️ Note

- Assicurati di avere abbastanza spazio su disco (>20 GB consigliati) prima di eseguire lo script.

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

❤️ Se trovi questo progetto utile, considera di lasciare una ⭐
