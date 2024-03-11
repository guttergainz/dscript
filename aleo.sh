#!/bin/bash

# Prompt for user input
read -p "Enter user ID: " DIR_NAME
CONTAINER_NAME="aleo_${DIR_NAME}"

mkdir -p "/root/${DIR_NAME}"
cd "/root/${DIR_NAME}"

# Create a Dockerfile
cat > Dockerfile << EOF
FROM rust:latest
RUN apt-get update && apt-get upgrade -y && apt-get install -y git curl
WORKDIR /aleo
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN git clone https://github.com/AleoHQ/snarkOS.git --depth 1
WORKDIR /aleo/snarkOS
RUN git fetch origin testnet3:testnet3
RUN git checkout testnet3
RUN ./build_ubuntu.sh
RUN cargo install --locked --path .
RUN snarkos account new
CMD ["./run-prover.sh"]
EOF

# Build the Docker image
docker build -t aleo-node .

# Run the Docker container, mounting the host directory
docker run -d --name "${CONTAINER_NAME}" \
  --restart unless-stopped \
  aleo-node
