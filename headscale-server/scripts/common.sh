#!/bin/sh
# Shared Headscale CLI helpers for user and preauth key management.
# Works both directly on the VPS (via local docker exec) and remotely from a PC when VPS_IP is set.

set -e

SSH_PRIV_KEY="${SSH_PRIV_KEY:-${HOME}/.ssh/id_ed25519}"
SSH_USER="${SSH_USER:-root}"

# Run a `headscale` CLI command inside the headscale container (locally or over SSH if VPS_IP is set).
# Args:
#   "$@": Arguments passed to the `headscale` binary inside the container.
# Example:
#   run_headscale users list
run_headscale() {
  if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx 'headscale'; then
    docker exec -e NO_COLOR=1 headscale headscale "$@"
  elif [ -n "${VPS_IP:-}" ]; then
    ssh -i "$SSH_PRIV_KEY" -o StrictHostKeyChecking=accept-new "${SSH_USER}@${VPS_IP}" \
      "docker exec -e NO_COLOR=1 headscale headscale $*"
  else
    echo "Error: headscale container is not running locally and VPS_IP is not set." >&2
    exit 1
  fi
}

# Create a Headscale user if it does not already exist.
# Args:
#   $1: Username to create.
# Example:
#   create_headscale_user "alice"
create_headscale_user() {
  target_user="$1"
  run_headscale users create "$target_user" >&2 2>/dev/null || true
}

# Resolve the numeric user ID for a given Headscale username.
# Args:
#   $1: Username to look up.
# Example:
#   USER_ID=$(get_headscale_user_id "alice")
get_headscale_user_id() {
  target_user="$1"
  users_table=$(run_headscale users list | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g')
  user_id=$(echo "$users_table" | grep -E "[|[:space:]]${target_user}[|[:space:]]" | grep -oE '^[[:space:]]*[0-9]+' | tr -d '[:space:]' | head -n 1)

  if [ -z "$user_id" ]; then
    echo "Error: could not find numeric user ID for '${target_user}'" >&2
    echo "$users_table" >&2
    return 1
  fi

  echo "$user_id"
}

# Generate a preauth key for a numeric user ID and print the clean key string.
# Args:
#   $1: Numeric user ID.
#   $2: Expiration duration (e.g. "1h", "24h").
#   $3 (optional): Extra flag such as "--reusable".
# Example:
#   create_headscale_preauthkey "1" "24h" "--reusable"
create_headscale_preauthkey() {
  uid="$1"
  expiration="${2:-24h}"
  extra_flag="${3:-}"

  if [ -n "$extra_flag" ]; then
    raw_out=$(run_headscale preauthkeys create --user "$uid" --expiration "$expiration" "$extra_flag")
  else
    raw_out=$(run_headscale preauthkeys create --user "$uid" --expiration "$expiration")
  fi

  echo "$raw_out" | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' | grep -oE '(hskey-auth-[A-Za-z0-9_-]+|[a-f0-9]{48,64})' | tail -n 1
}

