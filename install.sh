#!/bin/bash

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install CometBFT
cd $HOME
wget "https://github.com/cometbft/cometbft/releases/download/v0.37.2/cometbft_0.37.2_linux_amd64.tar.gz"
sudo tar -C /usr/local/bin -xf cometbft_0.37.2_linux_amd64.tar.gz cometbft
cometbft version

# Install namada binaires
cd $HOME
wget "https://github.com/anoma/namada/releases/download/v0.23.1/namada-0.23.1-Linux-x86_64.tar.gz"
tar -xf namada-v0.23.1-Linux-x86_64.tar.gz
cd namada-v0.23.1-Linux-x86_64/
sudo mv namada* /usr/local/bin/
cd ../
sudo rm -rf namada-v0.23.1-Linux-x86_64*
nammda --version

# Join the network
export CHAIN_ID="public-testnet-14.5d79b6958580" ## (replace with the actual chain-id)
namada client utils join-network --chain-id $CHAIN_ID

# Create systemd service
sudo tee /etc/systemd/system/namadad.service > /dev/null <<EOF
[Unit]
Description=namada
After=network-online.target

[Service]
User=$USER
ExecStart=/usr/local/bin/namada node ledger run
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

sudo systemctl daemon-reload
sudo systemctl enable namadad
sudo systemctl start namadad

# show node logs
journalctl -u namadad -fo cat
