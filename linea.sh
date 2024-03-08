#!/bin/bash

# Read the directory name as an input variable, if required
read -p "Enter directory name: " DIR_NAME

# Define Docker image and container names
IMAGE_NAME="ethereum-linea-node"
CONTAINER_NAME="ethereum-linea-node-container"

# Docker run command with a large series of setup commands executed in sequence
docker run -dit --name $CONTAINER_NAME \
    --restart unless-stopped \
    -v /root/${DIR_NAME}/linea/linea_data:/root/linea_data \
    ubuntu /bin/bash -c "\
    apt-get update && apt-get upgrade -y && \
    apt-get install software-properties-common screen wget -y && \
    add-apt-repository -y ppa:ethereum/ethereum && \
    apt-get update && \
    apt-get install ethereum -y && \
    wget https://docs.linea.build/files/genesis.json -O /root/genesis.json && \
    mkdir /root/linea_data && \
    geth --datadir /root/linea_data init /root/genesis.json && \
    screen -S linea -d -m geth \
        --datadir /root/linea_data \
        --networkid 59144 \
        --rpc.allow-unprotected-txs \
        --txpool.accountqueue 50000 \
        --txpool.globalqueue 50000 \
        --txpool.globalslots 50000 \
        --txpool.pricelimit 1000000 \
        --txpool.pricebump 1 \
        --txpool.nolocals \
        --http --http.addr '0.0.0.0' --http.port 8627 --http.corsdomain '*' --http.api 'web3,eth,txpool,net' --http.vhosts='*' \
        --ws --ws.addr '0.0.0.0' --ws.port 8628 --ws.origins '*' --ws.api 'web3,eth,txpool,net' \
        --bootnodes 'enode://...' \
        --discovery.port 30305 \
        --port 30305 \
        --syncmode full \
        --metrics \
        --verbosity 3"

echo "Ethereum Linea node container ($CONTAINER_NAME) is running."
