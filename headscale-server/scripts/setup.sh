#!/bin/sh
set -e

USER_NAME="${HEADSCALE_USER:-myuser}"

headscale users create "$USER_NAME" 2>/dev/null || echo "[setup] user '$USER_NAME' already exists"

echo "[setup] VPS node preauth key (1h, single-use):"
headscale preauthkeys create --user "$USER_NAME" --expiration 1h

echo "[setup] PC node preauth key (24h, reusable):"
headscale preauthkeys create --user "$USER_NAME" --expiration 24h --reusable
