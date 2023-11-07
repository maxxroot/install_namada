#!/bin/bash

# Variables
INSTALL_DIR="/usr/local/bin"
CHAIN_ID="public-testnet-14.5d79b6958580" # Remplacez par le testnet que vous voulez rejoindre

# Fonction pour gérer les erreurs
check_error() {
    if [ $? -ne 0 ]; then
        echo "Une erreur s'est produite. Arrêt du script."
        exit 1
    fi
}

# Vérification de l'existence de Rust
if ! command -v rustup &> /dev/null; then
    # Installation de Rust
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    check_error
fi

# Installation de CometBFT
if [[ ! -f "cometbft_0.37.2_linux_amd64.tar.gz" ]]; then
    wget "https://github.com/cometbft/cometbft/releases/download/v0.37.2/cometbft_0.37.2_linux_amd64.tar.gz"
    check_error
    sudo tar -C "$INSTALL_DIR" -xf cometbft_0.37.2_linux_amd64.tar.gz cometbft
    check_error
    cometbft version
fi

# Installation de namada binaires
if [[ ! -f "namada-0.23.1-Linux-x86_64.tar.gz" ]]; then
    wget "https://github.com/anoma/namada/releases/download/v0.23.1/namada-0.23.1-Linux-x86_64.tar.gz"
    check_error
    tar -xf namada-0.23.1-Linux-x86_64.tar.gz
    check_error
    sudo mv namada* "$INSTALL_DIR"
    check_error
    namada --version
    check_error
    rm -f namada-0.23.1-Linux-x86_64.tar.gz
fi

# Rejoindre le réseau
namada client utils join-network --chain-id "$CHAIN_ID"
check_error

# Créer le service systemd
sudo tee /etc/systemd/system/namadad.service > /dev/null <<EOF
[Unit]
Description=namada
After=network-online.target

[Service]
User=$USER
ExecStart=$INSTALL_DIR/namada node ledger run
Restart=always
RestartSec=10
LimitNOFILE=65535
Environment="NAMADA_LOG=info"
Environment="CMT_LOG_LEVEL=p2p:none,pex:error"
Environment="NAMADA_CMT_STDOUT=true"
Environment="NAMADA_LOG_COLOR=true"

[Install]
WantedBy=multi-user.target
EOF
check_error

# Recharger le démon systemd, activer et démarrer le service
sudo systemctl daemon-reload
sudo systemctl enable namadad
sudo systemctl start namadad

# Afficher les journaux du nœud
journalctl -u namadad -fo cat
