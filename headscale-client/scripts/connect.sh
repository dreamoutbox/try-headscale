#!/bin/sh
set -e

: "${HEADSCALE_URL:?HEADSCALE_URL not set}"
: "${TS_AUTHKEY:?TS_AUTHKEY not set}"

tailscale up \
  --login-server="${HEADSCALE_URL}" \
  --authkey="${TS_AUTHKEY}" \
  --hostname="${TS_HOSTNAME:-mypc}" \
  --accept-routes

# no network_mode: host, so the tun interface lives in this container's
# netns — forward incoming tailnet traffic on :8080 to the nginx container
apk add --no-cache socat >/dev/null
pkill socat 2>/dev/null || true
socat TCP-LISTEN:8080,fork,reuseaddr TCP:website:80 &

tailscale status
