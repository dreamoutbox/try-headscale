# Headscale & Tailscale Cheatsheet

## Quick Commands: List Users & Machines in Tailnet

### 1. List Users in Tailnet
Using server script (from PC via `VPS_IP`, or directly on VPS):
```bash
VPS_IP=104.248.156.42 ./headscale-server/scripts/list-users.sh
```

Raw command on the VPS:
```bash
docker exec headscale headscale users list
```

### 2. List Machines (Nodes) in Tailnet
Using server script (from PC via `VPS_IP`, or directly on VPS):
```bash
VPS_IP=104.248.156.42 ./headscale-server/scripts/list-machines.sh
```

Raw command on the VPS:
```bash
docker exec headscale headscale nodes list
```

From inside any connected Tailscale client (`ubuntu` container, `ts-client` container, or VPS):
```bash
tailscale status
```

---

## Helper Scripts in This Repo

### Create a User
Works both directly on the VPS or remotely from your PC when `VPS_IP` is set:
```bash
# Run from local PC via SSH:
VPS_IP=104.248.156.42 ./headscale-server/scripts/create-user.sh alice

# Or run directly on VPS:
./headscale-server/scripts/create-user.sh alice
```

### Create a Login Token (Preauth Key)
Automatically resolves the numeric User ID (`--user uint`) required by Headscale `v0.25+` and outputs a reusable token:
```bash
# Default 24h expiration:
VPS_IP=104.248.156.42 ./headscale-server/scripts/create-token.sh alice

# Custom expiration (e.g. 7d, 1h, 90d):
VPS_IP=104.248.156.42 ./headscale-server/scripts/create-token.sh alice 7d
```

### Client Script to Login to Tailnet
Installs Tailscale via `curl -fsSL https://tailscale.com/install.sh | sh` if not installed, resets `tailscaled` cleanly, and joins the tailnet:
```bash
# Non-interactive (pass env vars):
VPS_IP=104.248.156.42 TS_AUTHKEY=hskey-auth-... ./headscale-client/tailnet-login.sh

# Interactive prompt (asks for VPS_IP, TS_AUTHKEY, TS_HOSTNAME):
./headscale-client/tailnet-login-prompt.sh
# Or inside ubuntu / ubuntu2 container:
/scripts/tailnet-login-prompt.sh
```

### Client Script to Logout / Exit Tailnet
Logs out, invalidates the node key, clears `/var/lib/tailscale/tailscaled.state`, and restores container DNS:
```bash
./headscale-client/tailnet-logout.sh
# Or inside ubuntu / ubuntu2 container:
/scripts/tailnet-logout.sh
```

---

## Headscale Server CLI Reference (Run on VPS)

Prefix all commands with `docker exec headscale`:

### Users
```bash
# List all users
docker exec headscale headscale users list

# Create a user
docker exec headscale headscale users create <username>

# Rename a user (by numeric ID)
docker exec headscale headscale users rename --identifier <user_id> --new-name <new_username>

# Delete a user (by numeric ID)
docker exec headscale headscale users destroy --identifier <user_id>
```

### Preauth Keys (Login Tokens)
> Note: In Headscale `v0.25+`, `--user` requires the numeric User ID from `headscale users list`.

```bash
# List preauth keys for user ID 1
docker exec headscale headscale preauthkeys list --user 1

# Create a single-use 1h key for user ID 1
docker exec headscale headscale preauthkeys create --user 1 --expiration 1h

# Create a reusable 24h key for user ID 1
docker exec headscale headscale preauthkeys create --user 1 --expiration 24h --reusable

# Expire a preauth key
docker exec headscale headscale preauthkeys expire --user 1 <key_prefix_or_id>
```

### Nodes (Machines)
```bash
# List all registered machines
docker exec headscale headscale nodes list

# Rename a machine on the tailnet
docker exec headscale headscale nodes rename --identifier <node_id> <new_hostname>

# Expire (log out) a machine by node ID
docker exec headscale headscale nodes expire --identifier <node_id>

# Delete a machine from the tailnet by node ID
docker exec headscale headscale nodes delete --identifier <node_id> --force
```

### Routes (Subnet Routers & Exit Nodes)
```bash
# List advertised and enabled routes across nodes
docker exec headscale headscale nodes list-routes

# Approve/enable routes advertised by a node
docker exec headscale headscale nodes approve-routes --identifier <node_id> --routes "192.168.1.0/24"
```

---

## Tailscale Client CLI Reference (Run on Client)

### Status & IPs
```bash
# Show all peers and connection status (direct UDP vs DERP relay)
tailscale status

# Show this machine's tailnet IPv4 / IPv6 address
tailscale ip -4
tailscale ip -6
```

### Connectivity & Diagnostics
```bash
# Ping another tailnet peer at the WireGuard/Tailscale layer (shows DERP vs direct peer-to-peer)
tailscale ping <hostname_or_tailnet_ip>

# Check UDP/STUN/DERP connectivity and NAT type
tailscale netcheck

# Look up which user/machine owns a tailnet IP
tailscale whois 100.64.0.2
```

### Connecting & Disconnecting
```bash
# Connect / log in to Headscale
tailscale up \
  --login-server="http://<VPS_IP>:8080" \
  --authkey="<PREAUTH_KEY>" \
  --hostname="<HOSTNAME>" \
  --accept-routes

# Disconnect temporarily (keeps node registered)
tailscale down

# Bring connection back up without changing settings
tailscale up

# Log out and invalidate current node key
tailscale logout
```

