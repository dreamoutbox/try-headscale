#!/bin/sh
set -e

tailscaled --state=/var/lib/tailscale/tailscaled.state &
sleep infinity

