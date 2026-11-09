#!/bin/sh
set -e

: "${HEADSCALE_URL:?HEADSCALE_URL not set}"
: "${TS_AUTHKEY:?TS_AUTHKEY not set}"

tailscale up \
  --login-server="${HEADSCALE_URL}" \
  --authkey="${TS_AUTHKEY}" \
  --hostname="${TS_HOSTNAME:-mypc}" \
  --accept-routes

tailscale status
