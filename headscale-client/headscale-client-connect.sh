#!/usr/bin/env bash
set -euo pipefail

: "${VPS_IP:?Set VPS_IP, e.g. export VPS_IP=203.0.113.10}"
: "${TS_AUTHKEY:?Set TS_AUTHKEY from the 'PC node' preauth key printed by the server script}"
HEADSCALE_URL="${HEADSCALE_URL:-http://${VPS_IP}:8080}"

docker compose up -d

echo "Waiting for tailscaled to be ready..."
sleep 3

docker compose exec -T \
  -e HEADSCALE_URL="$HEADSCALE_URL" \
  -e TS_AUTHKEY="$TS_AUTHKEY" \
  -e TS_HOSTNAME="${TS_HOSTNAME:-mypc}" \
  tailscale sh /scripts/connect.sh

echo ""
echo "PC tailnet IP:"
docker compose exec -T tailscale tailscale ip -4
