#!/bin/bash

# Prompt for user input
read -p "Enter user ID: " DIR_NAME
CONTAINER_NAME="linea_${DIR_NAME}"

# Set up directory paths
HOST_DATA_DIR="/root/${DIR_NAME}/linea/linea_data"
GENESIS_FILE_URL="https://docs.linea.build/files/genesis.json"
GENESIS_FILE="/root/${DIR_NAME}/linea/genesis.json"

mkdir -p "${HOST_DATA_DIR}"
fallocate -l 200G "${HOST_DATA_DIR}/linea.img"
mkfs.ext4 "${HOST_DATA_DIR}/linea.img"
mount -o loop "${HOST_DATA_DIR}/linea.img" "${HOST_DATA_DIR}"

# Download the genesis file
if [ ! -f "${GENESIS_FILE}" ]; then
    echo "Downloading genesis file..."
    curl -o "${GENESIS_FILE}" "${GENESIS_FILE_URL}"
fi

while [ ! -s "${GENESIS_FILE}" ]; do
  echo "Waiting for genesis file to download..."
  sleep 1
done
echo "Genesis file downloaded."

cd "/root/${DIR_NAME}"

# Create a Dockerfile
cat > Dockerfile << EOF
FROM ubuntu:latest
WORKDIR /linea
COPY ./genesis.json /linea/genesis.json
RUN mkdir /linea/linea_data && \
    geth --datadir /linea/linea_data init /linea/genesis.json
EXPOSE 8627 8628 30305
CMD ["geth", "--datadir", "/linea/linea_data", "--networkid", "59144", "--rpc.allow-unprotected-txs", "--txpool.accountqueue", "50000", "--txpool.globalqueue", "50000", "--txpool.globalslots", "50000", "--txpool.pricelimit", "1000000", "--txpool.pricebump", "1", "--txpool.nolocals", "--http", "--http.addr", "0.0.0.0", "--http.port", "8627", "--http.corsdomain", "*", "--http.api", "web3,eth,txpool,net", "--http.vhosts", "*", "--ws", "--ws.addr", "0.0.0.0", "--ws.port", "8628", "--ws.origins", "*", "--ws.api", "web3,eth,txpool,net", "--bootnodes", "enode://...", "--discovery.port", "30305", "--port", "30305", "--syncmode", "full", "--metrics", "--verbosity", "3"]
EOF

# Build the Docker image
docker build --progress=plain --no-cache -t linea-node .

# Run the Docker container, mounting the host directory
docker run -d --name "${CONTAINER_NAME}" \
  -v "${HOST_DATA_DIR}:/root/${DIR_NAME}/linea/linea_data" \
  -p 8627:8627 -p 8628:8628 -p 30305:30305 \
  --restart unless-stopped \
  linea-node
