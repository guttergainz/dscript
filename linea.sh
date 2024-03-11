#!/bin/bash

# Prompt for user input
read -p "Enter user ID: " DIR_NAME
CONTAINER_NAME="linea_${DIR_NAME}"

# Set up directory paths
HOST_DATA_DIR="/root/${DIR_NAME}/linea/linea_data"
GENESIS_FILE_URL="https://docs.linea.build/files/genesis.json"
GENESIS_FILE="/root/${DIR_NAME}/linea/genesis.json"

mkdir -p "/root/${DIR_NAME}"
cd "/root/${DIR_NAME}"

# Create a Dockerfile
cat > Dockerfile << EOF
FROM ubuntu:latest
WORKDIR /linea
RUN apt-get update && apt-get install -y curl
RUN apt-get install software-properties-common -y
RUN add-apt-repository -y ppa:ethereum/ethereum
RUN apt-get update
RUN apt-get install ethereum -y
RUN curl -o "./genesis.json" "https://docs.linea.build/files/genesis.json"
RUN mkdir /linea/linea_data && \
    geth --datadir /linea/linea_data init /linea/genesis.json
EXPOSE 8627 8628 30305
CMD ["geth", "--datadir", "/linea/linea_data", "--networkid", "59144", "--rpc.allow-unprotected-txs", "--txpool.accountqueue", "50000", "--txpool.globalqueue", "50000", "--txpool.globalslots", "50000", "--txpool.pricelimit", "1000000", "--txpool.pricebump", "1", "--txpool.nolocals", "--http", "--http.addr", "0.0.0.0", "--http.port", "8627", "--http.corsdomain", "*", "--http.api", "web3,eth,txpool,net", "--http.vhosts", "*", "--ws", "--ws.addr", "0.0.0.0", "--ws.port", "8628", "--ws.origins", "*", "--ws.api", "web3,eth,txpool,net", "--bootnodes", "enode://ca2f06aa93728e2883ff02b0c2076329e475fe667a48035b4f77711ea41a73cf6cb2ff232804c49538ad77794185d83295b57ddd2be79eefc50a9dd5c48bbb2e@3.23.106.165:30303,enode://eef91d714494a1ceb6e06e5ce96fe5d7d25d3701b2d2e68c042b33d5fa0e4bf134116e06947b3f40b0f22db08f104504dd2e5c790d8bcbb6bfb1b7f4f85313ec@3.133.179.213:30303,enode://cfd472842582c422c7c98b0f2d04c6bf21d1afb2c767f72b032f7ea89c03a7abdaf4855b7cb2dc9ae7509836064ba8d817572cf7421ba106ac87857836fa1d1b@3.145.12.13:30303", "--discovery.port", "30305", "--port", "30305", "--syncmode", "full", "--metrics", "--verbosity", "3"]
EOF

# Build the Docker image
docker build --progress=plain --no-cache -t linea-node .

# Run the Docker container, mounting the host directory
docker run -d --name "${CONTAINER_NAME}" \
  -v "${HOST_DATA_DIR}:/root/${DIR_NAME}/linea/linea_data" \
  -p 8627:8627 -p 8628:8628 -p 30305:30305 \
  --restart unless-stopped \
  linea-node
