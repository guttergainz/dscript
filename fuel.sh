#!/bin/bash

# Prompt for user input
read -p "Enter user ID: " DIR_NAME
CONTAINER_NAME="fuel_${DIR_NAME}"

mkdir -p "/root/${DIR_NAME}"
cd "/root/${DIR_NAME}"

# Create a Dockerfile
cat > Dockerfile << EOF
FROM rust:latest
RUN apt-get update && apt-get upgrade -y && apt-get install -y curl
WORKDIR /fuel
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN curl https://install.fuel.network | sh -s -- -y
RUN curl -sSL https://raw.githubusercontent.com/FuelLabs/fuel-core/v0.22.0/deployment/scripts/chainspec/beta_chainspec.json > chainConfig.json
CMD fuel-core run \
    --service-name "$NAME" \
    --keypair "$KEYPAIR" \
    --relayer "$RELAYER" \
    --ip 0.0.0.0 --port 4631 --peering-port 35433 \
    --db-path /root/.fuel_beta5 \
    --chain /path/to/your/chainConfig.json \
    --utxo-validation --poa-instant false --enable-p2p \
    --min-gas-price 1 --max-block-size 18874368  --max-transmit-size 18874368 \
    --reserved-nodes /dns4/p2p-beta-5.fuel.network/tcp/30333/p2p/16Uiu2HAmSMqLSibvGCvg8EFLrpnmrXw1GZ2ADX3U2c9ttQSvFtZX,/dns4/p2p-beta-5.fuel.network/tcp/30334/p2p/16Uiu2HAmVUHZ3Yimoh4fBbFqAb3AC4QR1cyo8bUF4qyi8eiUjpVP \
    --sync-header-batch-size 100 \
    --enable-relayer \
    --relayer-v2-listening-contracts 0x557c5cE22F877d975C2cB13D0a961a182d740fD5 \
    --relayer-da-deploy-height 4867877 \
    --relayer-log-page-size 2000
EOF

# Build the Docker image
docker build -t fuel-node .

# Run the Docker container, mounting the host directory
# RUN fuel-core-keygen new --key-type peering
# docker run -d --name "${CONTAINER_NAME}" -e KEYPAIR='your_keypair' -e NAME='your_service_name' -e RELAYER='your_relayer' \
#   --restart unless-stopped \
#   fuel-node
