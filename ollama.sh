#!/bin/bash

echo "Cosa vuoi fare con il servizio Ollama e Chatbox Community Edition?"
echo "1) Avvia Ollama e Chatbox"
echo "2) Ferma Ollama"
read -p "Inserisci 1 o 2: " scelta

case "$scelta" in
  1)
    echo "Avvio del servizio Ollama..."
    sudo systemctl start ollama

    echo "Avvio di Chatbox Community Edition..."
    if [ -x "/opt/Chatbox CE/xyz.chatboxapp.ce" ]; then
      "/opt/Chatbox CE/xyz.chatboxapp.ce" & disown
      echo "Chatbox CE avviato correttamente in background."
    else
      echo "Errore: Chatbox CE non trovato o non eseguibile in /opt/Chatbox CE/"
    fi
    ;;
  2)
    echo "Arresto del servizio Ollama..."
    sudo systemctl stop ollama
    echo "Ollama fermato."
    ;;
  *)
    echo "Scelta non valida. Inserisci 1 per avviare o 2 per fermare."
    ;;
esac
