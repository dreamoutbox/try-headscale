#!/usr/bin/env bash
set -euo pipefail

: "${VPS_IP:?Set VPS_IP, e.g. export VPS_IP=203.0.113.10}"
SERVER_URL="${HEADSCALE_URL:-http://${VPS_IP}:8080}"
USER_NAME="${HEADSCALE_USER:-myuser}"

command -v docker >/dev/null || { echo "docker required"; exit 1; }

mkdir -p config data scripts
chmod +x scripts/setup.sh

sed -i "s|^server_url:.*|server_url: ${SERVER_URL}|" config/config.yaml

docker compose up -d

echo "Waiting for headscale to come up..."
until docker exec headscale headscale users list >/dev/null 2>&1; do sleep 1; done

echo "[setup] generating keys..."
RAW_KEYS=$(docker exec headscale sh /scripts/setup.sh "$USER_NAME")

# strip everything except the two 64-char hex keys, in order of appearance
VPS_KEY=$(echo "$RAW_KEYS" | grep -oE '[a-f0-9]{64}' | sed -n '1p')
PC_KEY=$(echo "$RAW_KEYS"  | grep -oE '[a-f0-9]{64}' | sed -n '2p')

[ -n "$VPS_KEY" ] || { echo "failed to extract VPS key"; echo "$RAW_KEYS"; exit 1; }

echo "[setup] joining VPS to tailnet as a node..."
command -v tailscale >/dev/null || curl -fsSL https://tailscale.com/install.sh | sh

tailscale up \
  --login-server="${SERVER_URL}" \
  --authkey="${VPS_KEY}" \
  --hostname="vps-relay"

echo ""
echo "VPS tailnet IP: $(tailscale ip -4)"
echo ""
echo "Give this to your PC's headscale-client-connect.sh:"
echo "VPS_IP=${VPS_IP} TS_AUTHKEY=${PC_KEY} ./headscale-client-connect.sh"
