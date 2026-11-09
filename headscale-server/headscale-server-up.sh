#!/usr/bin/env bash
set -euo pipefail

DOMAIN="${HEADSCALE_DOMAIN:?Set HEADSCALE_DOMAIN, e.g. export HEADSCALE_DOMAIN=headscale.yourdomain.com}"

command -v docker >/dev/null || { echo "docker required"; exit 1; }

mkdir -p config data scripts
chmod +x scripts/setup.sh

if [ ! -f config/config.yaml ]; then
  cat > config/config.yaml <<EOF
server_url: https://${DOMAIN}
listen_addr: 0.0.0.0:8080
metrics_listen_addr: 127.0.0.1:9090

database:
  type: sqlite
  sqlite:
    path: /var/lib/headscale/db.sqlite

prefixes:
  v4: 100.64.0.0/10

dns:
  magic_dns: true
  base_domain: tailnet.${DOMAIN#*.}
EOF
fi

docker compose up -d

echo "Waiting for headscale to come up..."
until docker exec headscale headscale users list >/dev/null 2>&1; do sleep 1; done

docker exec headscale sh /scripts/setup.sh

cat <<'EOF'

Next:
1. Join the VPS host itself to the tailnet (it's the relay, so it needs to be a node too):
     curl -fsSL https://tailscale.com/install.sh | sh
     tailscale up --login-server https://'"$DOMAIN"' --authkey <VPS_KEY_FROM_ABOVE>

2. Point Caddy (or your reverse proxy) at the headscale container:
     headscale.yourdomain.com { reverse_proxy 127.0.0.1:8080 }

3. Give the "PC node" preauth key above to your PC's headscale-client-connect.sh
EOF
