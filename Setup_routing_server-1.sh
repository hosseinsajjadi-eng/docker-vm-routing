#!/bin/bash

set -e

# =========================================================
# Server-1 Docker Routing Setup
# =========================================================

WAN_IF="enp0s3"
HOST_NETWORK="10.0.2.0/24"
DOCKER_NETWORK="192.168.2.0/24"
DOCKER_NETWORK_NAME="network1"

echo "=========================================="
echo " Docker Routing Setup"
echo "=========================================="

# ---------------------------------------------------------
# 1. Enable IPv4 forwarding
# ---------------------------------------------------------

echo "[1] Enabling IPv4 forwarding..."

sudo sysctl -w net.ipv4.ip_forward=1


# ---------------------------------------------------------
# 2. Detect Docker bridge
# ---------------------------------------------------------

echo "[2] Detecting Docker bridge..."

NETWORK_ID=$(docker network inspect "$DOCKER_NETWORK_NAME" \
    --format '{{.Id}}')

BRIDGE="br-${NETWORK_ID:0:12}"

if ! ip link show "$BRIDGE" >/dev/null 2>&1; then
    echo "ERROR: Docker bridge '$BRIDGE' was not found."
    exit 1
fi

echo "Docker bridge: $BRIDGE"


# ---------------------------------------------------------
# 3. Add FORWARD rule: Server-2 -> Docker
# ---------------------------------------------------------

echo "[3] Configuring forward rule: WAN -> Docker"

if sudo iptables -C FORWARD \
    -i "$WAN_IF" \
    -o "$BRIDGE" \
    -s "$HOST_NETWORK" \
    -d "$DOCKER_NETWORK" \
    -j ACCEPT 2>/dev/null; then

    echo "Rule already exists."

else

    sudo iptables -I FORWARD 1 \
        -i "$WAN_IF" \
        -o "$BRIDGE" \
        -s "$HOST_NETWORK" \
        -d "$DOCKER_NETWORK" \
        -j ACCEPT

    echo "Rule added."

fi


# ---------------------------------------------------------
# 4. Add FORWARD rule: Docker -> Server-2
# ---------------------------------------------------------

echo "[4] Configuring forward rule: Docker -> WAN"

if sudo iptables -C FORWARD \
    -i "$BRIDGE" \
    -o "$WAN_IF" \
    -s "$DOCKER_NETWORK" \
    -d "$HOST_NETWORK" \
    -j ACCEPT 2>/dev/null; then

    echo "Rule already exists."

else

    sudo iptables -I FORWARD 1 \
        -i "$BRIDGE" \
        -o "$WAN_IF" \
        -s "$DOCKER_NETWORK" \
        -d "$HOST_NETWORK" \
        -j ACCEPT

    echo "Rule added."

fi


# ---------------------------------------------------------
# 5. Show configuration
# ---------------------------------------------------------

echo
echo "=========================================="
echo " Configuration"
echo "=========================================="

echo
echo "IPv4 Forwarding:"
sysctl net.ipv4.ip_forward

echo
echo "Docker Bridge:"
echo "$BRIDGE"

echo
echo "FORWARD rules:"
sudo iptables -L FORWARD -n -v --line-numbers

echo
echo "=========================================="
echo " Setup completed successfully"
echo "=========================================="
