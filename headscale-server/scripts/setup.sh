#!/bin/sh
set -e

USER_NAME="${HEADSCALE_USER:-myuser}"

headscale users create "$USER_NAME" 2>/dev/null || true

# One key per line, nothing else — host script parses these directly
headscale preauthkeys create --user "$USER_NAME" --expiration 1h
headscale preauthkeys create --user "$USER_NAME" --expiration 24h --reusable
