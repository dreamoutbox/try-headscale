#!/usr/bin/env bash
# Open an interactive shell inside the ubuntu tailnet container (or run passed command).
#
# Inputs:
#   "$@" (optional): Command to execute inside the ubuntu container (default: bash).
#
# Example usage:
#   ./ubuntu-tailnet.sh
#   ./ubuntu-tailnet.sh curl http://mypc:8080

set -euo pipefail

if [ $# -eq 0 ]; then
  exec docker exec -it ubuntu bash
else
  exec docker exec -it ubuntu "$@"
fi

