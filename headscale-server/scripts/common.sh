#!/bin/sh
# Shared Headscale CLI helpers for user, node, and preauth key management.
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

# Strip ANSI escape codes from stdin.
# Args: none (reads stdin, writes stdout).
# Example:
#   run_headscale users list | strip_ansi
strip_ansi() {
  sed 's/\x1b\[[0-9;]*[a-zA-Z]//g'
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
  users_table=$(run_headscale users list | strip_ansi)
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

  echo "$raw_out" | strip_ansi | grep -oE '(hskey-auth-[A-Za-z0-9_-]+|[a-f0-9]{48,64})' | tail -n 1
}

# Resolve a node target (numeric ID, hostname, or IP) to its numeric Headscale node ID.
# Args:
#   $1: Node ID, hostname, or tailnet IP.
# Example:
#   NODE_ID=$(resolve_headscale_node_id "ubuntu2")
resolve_headscale_node_id() {
  target_node="$1"
  case "$target_node" in
    ''|*[!0-9]*)
      nodes_table=$(run_headscale nodes list | strip_ansi)
      node_id=$(echo "$nodes_table" | grep -E "[|[:space:],]${target_node}[|[:space:],]" | grep -oE '^[[:space:]]*[0-9]+' | tr -d '[:space:]' | head -n 1)
      if [ -z "$node_id" ]; then
        echo "Error: could not find numeric node ID for '${target_node}'" >&2
        echo "$nodes_table" >&2
        return 1
      fi
      echo "$node_id"
      ;;
    *)
      echo "$target_node"
      ;;
  esac
}

# Resolve a preauth token target (numeric ID, prefix, or full hskey-auth-... string) to its numeric ID.
# Args:
#   $1: Token ID, prefix, or full token string.
# Example:
#   KEY_ID=$(resolve_headscale_preauthkey_id "hskey-auth-H7j90s-...")
resolve_headscale_preauthkey_id() {
  target_key="$1"
  case "$target_key" in
    ''|*[!0-9]*)
      # Extract prefix if a full hskey-auth-<prefix>-<secret> token was passed
      clean_prefix=$(echo "$target_key" | sed 's/^hskey-auth-//' | cut -d'-' -f1)
      keys_table=$(run_headscale preauthkeys list | strip_ansi)
      key_id=$(echo "$keys_table" | grep -F "$clean_prefix" | grep -oE '^[[:space:]]*[0-9]+' | tr -d '[:space:]' | head -n 1)
      if [ -z "$key_id" ]; then
        echo "Error: could not find preauth key ID matching '${target_key}'" >&2
        echo "$keys_table" >&2
        return 1
      fi
      echo "$key_id"
      ;;
    *)
      echo "$target_key"
      ;;
  esac
}
