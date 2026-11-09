#!/bin/sh
# Reset tailscaled state in ts-client, join the Headscale tailnet, and forward :8080 to website:80.
#
# Inputs:
#   HEADSCALE_URL (env): Headscale control server URL (required).
#   TS_AUTHKEY    (env): Reusable preauth key from Headscale (required).
#   TS_HOSTNAME   (env): Tailnet hostname for this node (default: mypc).
#
# Example usage:
#   HEADSCALE_URL=http://203.0.113.10:8080 TS_AUTHKEY=<key> /scripts/connect.sh

set -e

: "${HEADSCALE_URL:?HEADSCALE_URL not set}"
: "${TS_AUTHKEY:?TS_AUTHKEY not set}"

pkill tailscaled 2>/dev/null || true
sleep 1
grep -q '127.0.0.11' /etc/resolv.conf || printf 'nameserver 127.0.0.11\noptions ndots:0\n' > /etc/resolv.conf

# Resolve the nginx container IP via Docker DNS (127.0.0.11)
WEBSITE_IP=$(getent hosts website | awk '{print $1}')
[ -n "$WEBSITE_IP" ] || { echo "Error: could not resolve website container IP" >&2; exit 1; }

apk add --no-cache socat >/dev/null

rm -f /var/lib/tailscale/tailscaled.state /var/run/tailscale/tailscaled.sock
nohup tailscaled --state=/var/lib/tailscale/tailscaled.state </dev/null >/var/log/tailscaled.log 2>&1 &
until [ -S /var/run/tailscale/tailscaled.sock ]; do
  sleep 1
done

tailscale up \
  --login-server="${HEADSCALE_URL}" \
  --authkey="${TS_AUTHKEY}" \
  --hostname="${TS_HOSTNAME:-mypc}" \
  --accept-routes \
  --accept-dns=false

# no network_mode: host, so the tun interface lives in this container's
# netns — forward incoming tailnet traffic on :8080 to the nginx container
pkill socat 2>/dev/null || true
nohup socat TCP-LISTEN:8080,fork,reuseaddr "TCP:${WEBSITE_IP}:80" </dev/null >/var/log/socat.log 2>&1 &

tailscale status
