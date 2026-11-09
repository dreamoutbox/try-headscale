# Playbook: What Happens When a Token Is Compromised & How to Deal With It

## 1. How Headscale Authentication Works (Preauth Token vs. Node Key)

Understanding what a leaked token can and cannot do requires distinguishing between **two separate keys**:

1. **Preauth Token (`TS_AUTHKEY` / `hskey-auth-...`)**:
   - Used **only once per machine during initial registration** (`tailscale up --authkey=...`).
   - Tells Headscale: *"Authorize this new machine under user `X` without interactive approval."*
   - If created with `--reusable`, multiple machines can use the same token until it expires.
2. **Node Key (stored in `/var/lib/tailscale/tailscaled.state`)**:
   - Generated locally by `tailscaled` when the machine registers.
   - Once registered, the machine **never sends the preauth token again** — all ongoing WireGuard and control-plane traffic uses the machine's **Node Key**.

### Key Takeaway
> Revoking a compromised preauth token stops **new** attacker machines from joining your tailnet, but it **will not disconnect** an attacker machine that has already used the token to join. You must **both** revoke the token **and** kick any unauthorized machines.

---

## 2. Immediate Response Playbook (Compromised Preauth Token)

### Step 1: Revoke the Compromised Preauth Token
Stop any new machines from registering with the leaked token.

```bash
# 1. Inspect existing tokens (shows ID, Prefix, User, Expiration, Reusable, Used):
VPS_IP=104.248.156.42 ./headscale-server/scripts/list-tokens.sh

# 2a. Revoke the specific token (by full token string, prefix, or numeric ID):
VPS_IP=104.248.156.42 ./headscale-server/scripts/revoke-token.sh hskey-auth-<compromised_token>
# or by ID:
VPS_IP=104.248.156.42 ./headscale-server/scripts/revoke-token.sh 2

# 2b. If unsure which token leaked, revoke ALL preauth tokens immediately:
VPS_IP=104.248.156.42 ./headscale-server/scripts/revoke-token.sh --all
```

### Step 2: Audit Joined Machines in the Tailnet
Check whether any unrecognized machine has already used the leaked token to register.

```bash
VPS_IP=104.248.156.42 ./headscale-server/scripts/list-machines.sh
```

Look for:
- Unknown `Hostname` or `Name` entries
- Unexpected `IP addresses` (`100.64.0.x`)
- Recent `Created` or `Last seen` timestamps after the token was created

### Step 3: Kick All Unauthorized or Suspicious Machines
Expire the rogue machine's session key and permanently delete its node record from Headscale:

```bash
# Kick by hostname, tailnet IP, or numeric Node ID:
VPS_IP=104.248.156.42 ./headscale-server/scripts/kick-machine.sh <rogue_hostname_or_ip_or_id>
```

What `kick-machine.sh` does under the hood:
1. `headscale nodes expire --identifier <id>` — immediately invalidates the node's key and pushes an updated netmap to all peers so they drop WireGuard packets from that node.
2. `headscale nodes delete --identifier <id> --force` — removes the node from the Headscale database.

### Step 4: Verify Clean State
Confirm no rogue tokens or machines remain:

```bash
VPS_IP=104.248.156.42 ./headscale-server/scripts/list-tokens.sh
VPS_IP=104.248.156.42 ./headscale-server/scripts/list-machines.sh
```

### Step 5: Issue a Fresh Token (If Needed)
When provisioning legitimate machines again, generate a new token with a short expiration:

```bash
VPS_IP=104.248.156.42 ./headscale-server/scripts/create-token.sh myuser 1h
```

---

## 3. What If an Already-Joined Machine Is Compromised?

If a legitimate machine (or container) that is already on the tailnet is compromised, the attacker has access to its `/var/lib/tailscale/tailscaled.state` (its Node Key).

1. **From the Headscale server (remotely kick the machine)**:
   ```bash
   VPS_IP=104.248.156.42 ./headscale-server/scripts/kick-machine.sh <compromised_hostname_or_id>
   ```
2. **From the machine itself (if you still have shell access)**:
   ```bash
   ./headscale-client/tailnet-logout.sh
   ```
3. **If the machine had a reusable preauth token in its shell history or environment**:
   Also revoke that token using `./headscale-server/scripts/revoke-token.sh`.

---

## 4. Prevention & Hardening Checklist

1. **Prefer short-lived tokens**: Use `1h` instead of `24h` or `90d` when creating tokens (`./headscale-server/scripts/create-token.sh myuser 1h`).
2. **Avoid `--reusable` when only adding one machine**: Single-use tokens automatically become invalid as soon as the first machine registers.
3. **Use interactive prompt login (`tailnet-login-prompt.sh`)**: Avoids leaving `TS_AUTHKEY=...` in `~/.bash_history`.
4. **Revoke unused tokens after deployment**: Run `VPS_IP=... ./headscale-server/scripts/revoke-token.sh --all` once all your machines have joined. Existing machines will stay connected using their node keys.

