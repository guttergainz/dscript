#!/bin/bash
read -p "Enter user ID: " DIR_NAME
CONTAINER_NAME="linea_${DIR_NAME}"

# Step 1: Create the Dockerfile
cat > Dockerfile << 'EOF'
FROM ubuntu:latest

# Install dependencies
RUN apt-get update && apt-get install -y software-properties-common wget && \
    add-apt-repository -y ppa:ethereum/ethereum && \
    apt-get update && \
    apt-get install -y ethereum

WORKDIR /root/linea

# Download the genesis file
RUN wget https://docs.linea.build/files/genesis.json

# Prepare data directory
RUN fallocate -l 200G /root/linea/linea.img && \
    mkfs.ext4 /root/linea/linea.img && \
    mkdir /root/linea/linea_data && \
    mount -o loop /root/linea/linea.img /root/linea/linea_data

# Initialize geth
RUN geth --datadir ./linea_data init ./genesis.json

EXPOSE 8627 8628 30305

CMD ["geth", \
    "--datadir", "linea_data", \
    "--networkid", "59144", \
    "--rpc.allow-unprotected-txs", \
    "--txpool.accountqueue", "50000", \
    "--txpool.globalqueue", "50000", \
    "--txpool.globalslots", "50000", \
    "--txpool.pricelimit", "1000000", \
    "--txpool.pricebump", "1", \
    "--txpool.nolocals", \
    "--http", "--http.addr", "0.0.0.0", "--http.port", "8627", "--http.corsdomain", "*", "--http.api", "web3,eth,txpool,net", "--http.vhosts", "*", \
    "--ws", "--ws.addr", "0.0.0.0", "--ws.port", "8628", "--ws.origins", "*", "--ws.api", "web3,eth,txpool,net", \
    "--bootnodes", "enode://...", \
    "--discovery.port", "30305", \
    "--port", "30305", \
    "--syncmode", "full", \
    "--metrics", \
    "--verbosity", "3"]
EOF

# Step 2: Build the Docker Image
docker build -t linea-node .

# Step 3: Run the Docker Container
docker run -d --name $CONTAINER_NAME -p 8627:8627 -p 8628:8628 -p 30305:30305 --restart unless-stopped linea-node
