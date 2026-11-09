#!/usr/bin/env bash
# Interactively prompt the user for Headscale connection variables and run tailnet-login.sh.
#
# Prompts for:
#   VPS_IP:      VPS IPv4 address running Headscale (required).
#   TS_AUTHKEY:  Preauth token from create-token.sh (required).
#   TS_HOSTNAME: Hostname to register in tailnet (default: system hostname).
#
# Example usage:
#   /scripts/tailnet-login-prompt.sh

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEFAULT_HOSTNAME=$(hostname)

read -r -p "VPS_IP [${VPS_IP:-}]: " INPUT_VPS_IP
VPS_IP="${INPUT_VPS_IP:-${VPS_IP:-}}"
if [ -z "$VPS_IP" ]; then
  echo "Error: VPS_IP is required." >&2
  exit 1
fi

read -r -p "TS_AUTHKEY [${TS_AUTHKEY:-}]: " INPUT_TS_AUTHKEY
TS_AUTHKEY="${INPUT_TS_AUTHKEY:-${TS_AUTHKEY:-}}"
if [ -z "$TS_AUTHKEY" ]; then
  echo "Error: TS_AUTHKEY is required." >&2
  exit 1
fi

read -r -p "TS_HOSTNAME [${TS_HOSTNAME:-${DEFAULT_HOSTNAME}}]: " INPUT_TS_HOSTNAME
TS_HOSTNAME="${INPUT_TS_HOSTNAME:-${TS_HOSTNAME:-${DEFAULT_HOSTNAME}}}"

export VPS_IP TS_AUTHKEY TS_HOSTNAME
exec "${SCRIPT_DIR}/tailnet-login.sh"

