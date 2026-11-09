#!/usr/bin/env bash
set -euo pipefail

: "${HEADSCALE_URL:?Set HEADSCALE_URL, e.g. export HEADSCALE_URL=https://headscale.yourdomain.com}"
: "${TS_AUTHKEY:?Set TS_AUTHKEY from the 'PC node' preauth key printed by the server script}"

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
