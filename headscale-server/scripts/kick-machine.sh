#!/usr/bin/env bash
# Kick (expire and delete) a machine from the Headscale tailnet.
# Accepts a numeric node ID, hostname, or tailnet IPv4 address.
#
# Inputs:
#   $1 (required): Node ID (e.g. 2), hostname (e.g. ubuntu2), or IP (e.g. 100.64.0.3).
#   VPS_IP  (env): Optional VPS IPv4 address if running from a remote machine.
#
# Example usage:
#   VPS_IP=104.248.156.42 ./headscale-server/scripts/kick-machine.sh ubuntu2
#   VPS_IP=104.248.156.42 ./headscale-server/scripts/kick-machine.sh 3

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/common.sh"

TARGET_NODE="${1:-}"
if [ -z "$TARGET_NODE" ]; then
  echo "Usage: $0 <node_id_or_hostname_or_ip>" >&2
  echo "" >&2
  echo "Current machines in tailnet:" >&2
  run_headscale nodes list >&2
  exit 1
fi

NODE_ID=$(resolve_headscale_node_id "$TARGET_NODE")

echo "Expiring session for node ID ${NODE_ID} (${TARGET_NODE})..."
run_headscale nodes expire --identifier "$NODE_ID"

echo "Deleting node ID ${NODE_ID} (${TARGET_NODE}) from tailnet..."
run_headscale nodes delete --identifier "$NODE_ID" --force

echo ""
echo "Remaining machines in tailnet:"
run_headscale nodes list

