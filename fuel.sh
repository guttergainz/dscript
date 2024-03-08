#!/bin/bash

# Ensure Docker is installed and start Docker if not already running
which docker >/dev/null || { echo "Docker is not installed. Please install Docker first."; exit 1; }
sudo systemctl start docker

# Define the environment variables for configuration
read -p "Enter value for private key: " PRIVATE_KEY
read -p "Enter value for node name: " NODE_NAME
read -p "Enter value for RPC endpoint: " RPC_ENDPOINT

# Define Docker image and container names
IMAGE_NAME="fuel-node"
CONTAINER_NAME="fuel-node-container"

# Pull an Ubuntu image and create a Dockerfile commands
DOCKERFILE_COMMANDS=$(cat <<EOF
FROM ubuntu:latest
RUN apt-get update && apt-get upgrade -y && apt-get install -y curl screen git
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN /bin/bash -c "source \$HOME/.cargo/env"
RUN curl https://install.fuel.network | sh
RUN mkdir -p /fuel
WORKDIR /fuel
RUN curl -sSL https://raw.githubusercontent.com/FuelLabs/fuel-core/v0.22.0/deployment/scripts/chainspec/beta_chainspec.json > chainConfig.json
RUN /bin/bash -c "source \$HOME/.cargo/env; fuel-core-keygen new --key-type peering"
CMD fuel-core run \\
--service-name "${NODE_NAME}" \\
--keypair "${PRIVATE_KEY}" \\
--relayer "${RPC_ENDPOINT}" \\
--ip 0.0.0.0 --port 4631 --peering-port 35433 \\
--db-path  /root/.fuel_beta5 \\
--chain ./chainConfig.json \\
--utxo-validation --poa-instant false --enable-p2p \\
--min-gas-price 1 --max-block-size 18874368  --max-transmit-size 18874368 \\
--reserved-nodes /dns4/p2p-beta-5.fuel.network/tcp/30333/p2p/16Uiu2HAmSMqLSibvGCvg8EFLrpnmrXw1GZ2ADX3U2c9ttQSvFtZX,/dns4/p2p-beta-5.fuel.network/tcp/30334/p2p/16Uiu2HAmVUHZ3Yimoh4fBbFqAb3AC4QR1cyo8bUF4qyi8eiUjpVP \\
--sync-header-batch-size 100 \\
--enable-relayer \\
--relayer-v2-listening-contracts 0x557c5cE22F877d975C2cB13D0a961a182d740fD5 \\
--relayer-da-deploy-height 4867877 \\
--relayer-log-page-size 2000
EOF
)

# Create a temporary Dockerfile
DOCKERFILE_PATH=$(mktemp)
echo "$DOCKERFILE_COMMANDS" > "$DOCKERFILE_PATH"

# Build the Docker image
docker build -t $IMAGE_NAME -f "$DOCKERFILE_PATH" .

# Run the container with restart policy
docker run -d --restart unless-stopped --name $CONTAINER_NAME $IMAGE_NAME

# Cleanup Dockerfile
rm "$DOCKERFILE_PATH"

echo "Fuel node container ($CONTAINER_NAME) is running."
