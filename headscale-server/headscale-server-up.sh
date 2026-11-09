#!/usr/bin/env bash
set -euo pipefail

: "${VPS_IP:?Set VPS_IP, e.g. export VPS_IP=203.0.113.10}"
SERVER_URL="${HEADSCALE_URL:-http://${VPS_IP}:8080}"
USER_NAME="${HEADSCALE_USER:-myuser}"

echo "[debug] VPS_IP=${VPS_IP}"
echo "[debug] SERVER_URL=${SERVER_URL}"
echo "[debug] USER_NAME=${USER_NAME}"

command -v docker >/dev/null || { echo "docker required"; exit 1; }

mkdir -p config data scripts
chmod +x scripts/setup.sh

sed -i "s|^server_url:.*|server_url: ${SERVER_URL}|" config/config.yaml
echo "[debug] updated config/config.yaml server_url:"
grep "^server_url:" config/config.yaml

docker compose up -d --force-recreate

echo "Waiting for headscale to come up..."
until docker exec headscale headscale users list >/dev/null 2>&1; do
  echo "[debug] waiting for headscale container to be ready..."
  sleep 1
done

echo "[setup] generating keys..."
if ! RAW_KEYS=$(./scripts/setup.sh "$USER_NAME" 2>&1); then
  echo "[error] ./scripts/setup.sh failed. Output:"
  echo "$RAW_KEYS"
  echo "[debug] docker logs headscale:"
  docker logs --tail 50 headscale || true
  exit 1
fi

echo "[debug] RAW_KEYS output:"
echo "$RAW_KEYS"

# strip everything except the two preauth keys, in order of appearance
VPS_KEY=$(echo "$RAW_KEYS" | grep -oE '(hskey-auth-[A-Za-z0-9_-]+|[a-f0-9]{48,64})' | sed -n '1p' || true)
PC_KEY=$(echo "$RAW_KEYS"  | grep -oE '(hskey-auth-[A-Za-z0-9_-]+|[a-f0-9]{48,64})' | sed -n '2p' || true)

echo "[debug] extracted VPS_KEY=${VPS_KEY}"
echo "[debug] extracted PC_KEY=${PC_KEY}"

[ -n "$VPS_KEY" ] || { echo "failed to extract VPS key"; echo "$RAW_KEYS"; exit 1; }
[ -n "$PC_KEY" ]  || { echo "failed to extract PC key"; echo "$RAW_KEYS"; exit 1; }

echo "[setup] joining VPS to tailnet as a node..."
command -v tailscale >/dev/null || curl -fsSL https://tailscale.com/install.sh | sh

tailscale up \
  --login-server="${SERVER_URL}" \
  --authkey="${VPS_KEY}" \
  --hostname="vps-relay" \
  --force-reauth \
  --reset

echo ""
echo "VPS tailnet IP: $(tailscale ip -4)"
echo ""
echo "Give this to your PC's headscale-client-connect.sh:"
echo "VPS_IP=${VPS_IP} TS_AUTHKEY=${PC_KEY} ./headscale-client-connect.sh"
