#!/usr/bin/env bash
# Start the local Docker containers (website, ts-client, ubuntu) and connect both
# ts-client and ubuntu to the Headscale tailnet.
#
# Inputs:
#   VPS_IP          (env): VPS IPv4 address running Headscale (required).
#   TS_AUTHKEY      (env): Reusable preauth key printed by headscale-server-up.sh (required).
#   TS_HOSTNAME     (env): Tailnet hostname for the website proxy node (default: mypc).
#   UBUNTU_HOSTNAME (env): Tailnet hostname for the Ubuntu test node   (default: ubuntu).
#
# Example usage:
#   VPS_IP=203.0.113.10 TS_AUTHKEY=<key> ./headscale-client-connect.sh

set -euo pipefail

: "${VPS_IP:?Set VPS_IP, e.g. export VPS_IP=203.0.113.10}"
: "${TS_AUTHKEY:?Set TS_AUTHKEY from the 'PC node' preauth key printed by the server script}"
HEADSCALE_URL="${HEADSCALE_URL:-http://${VPS_IP}:8080}"

docker compose up -d

echo "Waiting for tailscaled to be ready..."
sleep 3

echo "[1/2] Connecting ts-client (${TS_HOSTNAME:-mypc}) to tailnet..."
docker compose exec -T \
  -e HEADSCALE_URL="$HEADSCALE_URL" \
  -e TS_AUTHKEY="$TS_AUTHKEY" \
  -e TS_HOSTNAME="${TS_HOSTNAME:-mypc}" \
  tailscale sh /scripts/connect.sh

echo "[2/2] Connecting ubuntu (${UBUNTU_HOSTNAME:-ubuntu}) to tailnet..."
docker compose exec -T \
  -e HEADSCALE_URL="$HEADSCALE_URL" \
  -e TS_AUTHKEY="$TS_AUTHKEY" \
  -e UBUNTU_HOSTNAME="${UBUNTU_HOSTNAME:-ubuntu}" \
  ubuntu sh /scripts/connect-ubuntu.sh

PC_TAILNET_IP=$(docker compose exec -T tailscale tailscale ip -4 | tr -d '\r')
UBUNTU_TAILNET_IP=$(docker compose exec -T ubuntu tailscale ip -4 | tr -d '\r')

echo ""
echo "PC (ts-client) tailnet IP: ${PC_TAILNET_IP}"
echo "Ubuntu tailnet IP:         ${UBUNTU_TAILNET_IP}"
echo ""
echo "Open an interactive shell in the ubuntu container with:"
echo "  ./ubuntu-tailnet.sh"
echo "Then test curling the website over the tailnet:"
echo "  curl http://${PC_TAILNET_IP}:8080"
echo "  curl http://${TS_HOSTNAME:-mypc}:8080"
