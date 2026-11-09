#!/usr/bin/env bash
# Revoke (expire and delete) a compromised Headscale preauth token, or all tokens with --all.
# Accepts a numeric key ID, key prefix, full hskey-auth-... token string, or --all.
#
# Inputs:
#   $1 (required): Key ID (e.g. 2), key prefix, full hskey-auth-... string, or "--all".
#   VPS_IP  (env): Optional VPS IPv4 address if running from a remote machine.
#
# Example usage:
#   VPS_IP=104.248.156.42 ./headscale-server/scripts/revoke-token.sh hskey-auth-H7j90s-...
#   VPS_IP=104.248.156.42 ./headscale-server/scripts/revoke-token.sh 2
#   VPS_IP=104.248.156.42 ./headscale-server/scripts/revoke-token.sh --all

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/common.sh"

TARGET_KEY="${1:-}"
if [ -z "$TARGET_KEY" ]; then
  echo "Usage: $0 <key_id_or_prefix_or_full_token | --all>" >&2
  echo "" >&2
  echo "Current preauth tokens:" >&2
  run_headscale preauthkeys list >&2
  exit 1
fi

# Revoke a single preauth key by its numeric ID.
# Args:
#   $1: Numeric preauth key ID.
# Example:
#   revoke_single_key 2
revoke_single_key() {
  kid="$1"
  echo "Expiring preauth key ID ${kid}..."
  run_headscale preauthkeys expire --id "$kid" || true
  echo "Deleting preauth key ID ${kid}..."
  run_headscale preauthkeys delete --id "$kid" --force || true
}

if [ "$TARGET_KEY" = "--all" ]; then
  KEYS_TABLE=$(run_headscale preauthkeys list | strip_ansi)
  KEY_IDS=$(echo "$KEYS_TABLE" | grep -oE '^[[:space:]]*[0-9]+' | tr -d '[:space:]' || true)
  if [ -z "$KEY_IDS" ]; then
    echo "No preauth tokens found."
    exit 0
  fi
  for kid in $KEY_IDS; do
    revoke_single_key "$kid"
  done
else
  KEY_ID=$(resolve_headscale_preauthkey_id "$TARGET_KEY")
  revoke_single_key "$KEY_ID"
fi

echo ""
echo "Remaining preauth tokens:"
run_headscale preauthkeys list

