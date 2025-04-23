FROM ubuntu:latest

RUN apt-get update && apt-get upgrade -y && \
apt-get install curl git jq lz4 build-essential make wget -y

ENV HOME=/app \
NODENAME="Stake Shark" \
CHAIN_ID="nillion-1" \
GO_VER="1.22.3" \
WALLET="wallet" \
PATH="/usr/local/go/bin:/app/go/bin:${PATH}" \
DAEMON_NAME=nilchaind \
DAEMON_HOME=/app/.nillionapp \
DAEMON_ALLOW_DOWNLOAD_BINARIES=false \
DAEMON_RESTART_AFTER_UPGRADE=true

WORKDIR /app

RUN wget "https://golang.org/dl/go$GO_VER.linux-amd64.tar.gz" && \
tar -C /usr/local -xzf "go$GO_VER.linux-amd64.tar.gz" && \
rm "go$GO_VER.linux-amd64.tar.gz" && \
mkdir -p go/bin

RUN git clone https://github.com/NillionNetwork/nilchain.git && \
cd nilchain && \
git checkout v0.2.5 && \
make build && \
mkdir -p $HOME/.nillionapp/cosmovisor/genesis/bin && \
mv build/nilchaind $HOME/.nillionapp/cosmovisor/genesis/bin/ && \
rm -rf build

RUN go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

RUN /app/.nillionapp/cosmovisor/genesis/bin/nilchaind init "Stake Shark" --chain-id=nillion-1

RUN curl -Ls https://snapshots.kjnodes.com/nillion/genesis.json > $HOME/.nillionapp/config/genesis.json && \
curl -Ls https://snapshots.kjnodes.com/nillion/addrbook.json > $HOME/.nillionapp/config/addrbook.json

RUN sed -i.bak -e "s/^external_address *=.*/external_address = \"$(wget -qO- eth0.me):26656\"/" $HOME/.nillionapp/config/config.toml && \
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0unil\"|" $HOME/.nillionapp/config/app.toml && \
sed -i 's/max_num_inbound_peers =.*/max_num_inbound_peers = 40/g' $HOME/.nillionapp/config/config.toml && \
sed -i 's/max_num_outbound_peers =.*/max_num_outbound_peers = 10/g' $HOME/.nillionapp/config/config.toml && \
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.nillionapp/config/app.toml && \
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"1000\"/" $HOME/.nillionapp/config/app.toml && \
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" $HOME/.nillionapp/config/app.toml && \
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.nillionapp/config/config.toml && \
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.nillionapp/config/config.toml && \
sed -i "s/snapshot-interval *=.*/snapshot-interval = 0/g" $HOME/.nillionapp/config/app.toml

RUN echo '#!/bin/sh' > /app/entrypoint.sh && \
    echo 'sleep 10000' >> /app/entrypoint.sh && \
    chmod +x /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
