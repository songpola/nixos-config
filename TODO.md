# TODO

Remaining work on prts after switching to the overlay storage driver (graph root
on the `@containers` btrfs subvolume, named volumes in `/tank/v2/podman-volumes`),
plus the planned central auth (section 4). Commands are nushell, run on prts
unless noted.

Volume exports are in `/tank/v2/backups/podman-volumes-2026-10-04/`.

## 1. Bring the stacks back

Stacks live in `/tank/v2/services/dockhand/stacks`; deploy them from Dockhand.

- [ ] Stacks without named volumes: `cwa`, `forgejo`, `kay-chan-discord-bot`,
      `mc-all-the-mons`, `unturned-server`, `speedtest` (images are pulled again,
      so the first start is slow)
- [ ] Remove the `dozzle` stack in Dockhand (Dozzle now runs from Nix:
      `services.dozzle`; its old volume `dozzle_dozzle-data` is empty)
- [ ] New stacks from `modules/hosts/prts/stacks/`: `protonmail-bridge`,
      `starrs` (includes qui; to be renamed `arrs`, see section 4 "Later"),
      `jellyfin` (check the GPU is visible: `nvidia-smi` in the container)
- [ ] Only if still wanted, `ite-310-wordpress` and `ite-444-full-stack`
      (databases in named volumes; create, import, then start):
  ```nu
  let b = "/tank/v2/backups/podman-volumes-2026-10-04"
  cd /tank/v2/services/dockhand/stacks/ite-310-wordpress
  sudo podman compose create
  sudo podman volume import ite-310-wordpress_db-data $"($b)/ite-310-wordpress_db-data.tar"
  sudo podman volume import ite-310-wordpress_wp-data $"($b)/ite-310-wordpress_wp-data.tar"
  sudo podman compose start
  # ite-444-full-stack: same, with ite-444-full-stack_dbdata (also builds an image)
  ```
- [ ] Not restored on purpose: `mystifying_agnesi`, `arcane-data`,
      `netnow_db-data`, `buildx_buildkit_default_state` (tars kept as archives)
- Radicale is dropped (no longer used). `stacks/radicale/compose.yaml` stays as a
  reference only; its data is in `/tank/radicale`.

## 2. Verify

- [ ] Dockhand is responsive (turn off "Disk space warnings" in the environment's
      Activity tab if it is still slow)
- [ ] Restart on boot works: reboot, or `sudo systemctl restart podman-restart`
      (briefly stops every container); expect `active (exited)`
  ```nu
  systemctl status podman-restart
  sudo podman ps
  ```

## 3. Caddy

Runs from Nix (`services.caddy-reverse-proxy`, `oci-containers`, token via
sops-nix); stacks join the `caddy` network (renamed from
`caddy-reverse-proxy-ingress`). Deployed and working: it serves a valid Let's
Encrypt certificate for `dockhand.songpola.dev` (checked 2026-10-06), so
restoring `caddy-reverse-proxy-data.tar` is not needed (keep it as an archive).

- [ ] Once the `dozzle` stack is removed, delete the old network and the
      `compose.yaml.bak` files in the stacks:
  ```nu
  sudo podman network rm caddy-reverse-proxy-ingress
  ```

## 4. Central auth (Kanidm + oauth2-proxy)

Status: planned, nothing implemented yet (plan saved 2026-10-06, reviewed
against the current setup the same day).

Goal: one login (passkeys) for the web services on prts, behind Caddy. Access
stays Tailscale-only (`*.songpola.dev A <Tailscale IP>`).

### Decisions

- **Kanidm** is the only identity provider (users, groups, passkeys, OIDC).
  Authelia was dropped: its passkeys count as one factor, it can't take Kanidm as
  an upstream (LDAP only, read-only, separate POSIX password), and it would
  duplicate Kanidm.
- **oauth2-proxy** is the forward-auth gate for apps without usable auth; Caddy
  asks it on every request.
- Domains: `idm.songpola.dev` (Kanidm; passkeys are bound to it, never change
  it), `auth.songpola.dev` (oauth2-proxy). Later: `home.songpola.dev`.
- Kanidm runs **natively** (NixOS `services.kanidm`) so `provision` can declare
  users, groups and OIDC clients in Nix; the upstream container image has no
  secret-provisioning patches. oauth2-proxy runs as a **container** on the
  `caddy` network (stateless, only Caddy talks to it, no firewall rule).
- Package: `kanidmWithSecretProvisioning_<version>`. The patches let sops files
  supply OIDC client secrets (`basicSecretFile`) and admin passwords; plain
  `kanidm` generates random secrets you would copy into sops by hand. 1.11 is in
  cache.nixos.org and in the pinned nixpkgs (no 1.12 yet).
- Kanidm only supports upgrading to the adjacent release (each upgrade migrates
  the database), and nixpkgs marks a version vulnerable 30 days after its
  successor ships. The unversioned `kanidm` alias is removed, so the version is
  one explicit setting (`version = "1_11"`) with a comment explaining this.
- TLS: Kanidm serves TLS itself, so use a real certificate for `idm.songpola.dev`
  from `security.acme` (Cloudflare DNS-01), readable by the `kanidm` group,
  restart `kanidm` on renewal. Caddy then verifies it
  (`tls_server_name idm.songpola.dev`).
- The Cloudflare token is **shared** between Caddy and ACME: the existing secret
  is a bare token that Caddy reads with `{file.<path>}`, and ACME can read the
  same decrypted file through
  `security.acme.certs.<name>.credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE`
  (no env-file template). Declare the sops secret once.
- Caddy runs in a container, Kanidm on the host: Caddy proxies to
  `https://host.containers.internal:8443` (checked: that is `10.89.1.1`, the
  `caddy` network's bridge gateway). Kanidm binds `0.0.0.0:8443`; the firewall
  allows 8443 from `podman*` interfaces (wildcard, bridge names are dynamic; like
  the DNS rule in `modules/programs/podman.nix`). The LAN stays blocked, but
  Tailscale accepts everything arriving on `tailscale0`, so the tailnet can reach
  8443 directly; fine for an IdP with its own TLS.
- Storage: database stays at `/var/lib/kanidm` on the root SSD (path is fixed by
  the module). Online backups go to `/tank/v2/services/kanidm/backups` so ZFS
  snapshots and the planned syncoid replication cover them.
- LDAP stays off until an app needs it.
- Tailnet auto-allow / tsidp: deferred.
- **Lock-out risk:** with Dockhand and Dozzle behind Kanidm and oauth2-proxy, an
  outage of those two locks you out of the tools you would use to debug it.
  Break-glass is SSH (Tailscale SSH) plus isd. Do not use the `port` option of
  `services.dockhand` / `services.dozzle` as one: a published port skips the
  gate for anyone on the tailnet.

### Steps

1. [ ] **Secrets move.** Move `caddy-reverse-proxy.secrets.yaml` into
   `modules/hosts/prts/secrets/` and rename it `cloudflare.secrets.yaml` (it
   serves Caddy and ACME); renaming the key inside goes through `just sops-edit`.
   New `secrets/auth.secrets.yaml` with the oauth2-proxy client secret (shared
   with Kanidm provisioning), the cookie secret, optionally the `idm_admin`
   password. Update the path in `modules/hosts/prts/default.nix`, the key in the
   `services.caddy-reverse-proxy` option description, the `justfile` example and
   CLAUDE.md. `.sops.yaml` has no path filter, so it needs no change.
2. [ ] **Caddy** (`services.caddy-reverse-proxy`): add a NixOS option (e.g.
   `extraConfig`, `types.lines`) in the aspect's `nixos` module so other aspects
   can append snippets. It can't be an aspect setting: settings are only set by
   the host, so other aspects can't add to them.
   - `(auth)` snippet: strip client-supplied `X-Auth-Request-*`, `forward_auth`
     to `oauth2-proxy:4180` at `/oauth2/auth?allowed_groups={args[0]}`, redirect
     401 to `https://auth.songpola.dev/oauth2/start?rd=...`. Apps opt in with the
     label `caddy.import: auth <group>`.
   - Kanidm's site block (`idm.songpola.dev`) can be labels on the Caddy
     container itself (oci-containers `labels` merge across modules, and
     caddy-docker-proxy reads its own labels), so only the snippet needs the
     option.
   - Give the Caddy container the network alias
     `networks = [ "caddy:alias=idm.songpola.dev" ]`, so containers on `caddy`
     resolve `idm.songpola.dev` to Caddy directly instead of looping through the
     host's Tailscale IP (see "Verify" 1).
3. [ ] **`services.kanidm`** (new aspect, native): settings `version`, `domain`,
   `backupDir`, optional `ldap`; ACME certificate; firewall rule; Caddy site
   block for `idm.songpola.dev`. Enroll your passkey in the web UI.
4. [ ] **`services.oauth2-proxy`** (new aspect, container): Kanidm OIDC with PKCE
   S256, `--cookie-domain=.songpola.dev`, `--whitelist-domain=.songpola.dev`,
   `--set-xauthrequest`, username from `preferred_username` (Kanidm's `sub` is a
   UUID). Secrets via an env file from sops. Caddy site block
   `auth.songpola.dev`.
5. [ ] **Kanidm provisioning** (in `modules/hosts/prts/`): person `songpola`,
   groups, OIDC client `oauth2-proxy`.
6. [ ] **Apps (only these for now).** Dozzle: `import auth <admin group>`; new
   `settings.auth` option sets `DOZZLE_AUTH_PROVIDER=forward-proxy` and
   `DOZZLE_AUTH_HEADER_*` to `X-Auth-Request-*`. Dockhand: `import auth <admin
   group>`; check whether it supports OIDC and whether its own login can be
   turned off or kept as a second layer.
7. [ ] **Version-bump workflow** `.github/workflows/bump-kanidm.yml`, weekly
   after `update-flake-lock`: if the locked nixpkgs has `kanidm_1_<n+1>`, open a
   PR that changes only the version setting. CI builds prts, merging deploys via
   the nightly auto-upgrade. If a version goes EOL first, CI on the flake.lock PR
   fails, which says to merge the Kanidm bump first.

### Open questions

- **Group names**: decide later (candidates: `prts_admins`, `prts_media`).

### Verify while implementing

Already checked: `host.containers.internal` is the bridge gateway; the pinned
nixpkgs has `kanidmWithSecretProvisioning_1_11`, `services.kanidm.provision` and
`credentialFiles`.

1. oauth2-proxy container reaching `https://idm.songpola.dev` (resolves to the
   host's own Tailscale IP). The Caddy network alias in step 2 should avoid the
   loop (nixpkgs passes the network string through unchanged; the alias itself is
   untested on prts). Otherwise point the backend URLs at Kanidm directly and
   keep the issuer URL unchanged.
2. Kanidm sends groups as `name@idm.songpola.dev`; `allowed_groups` must match.
3. caddy-docker-proxy's `import` with arguments through labels works with the
   snippet.
4. Caddy's access log shows `100.x` client IPs, not a Podman gateway address
   (only matters if IP-based rules are added later).
5. Whether Dockhand supports OIDC.

### Later

- **Dashboard at `home.songpola.dev`**, behind `import auth`; the `.songpola.dev`
  cookie already covers it. It could read `X-Auth-Request-Groups` to show links
  per group; Kanidm's own app list is at `idm.songpola.dev/ui/apps`.
- **arrs stack**: the "starrs" stack is now called "arrs" (not renamed in the repo
  yet). Gate it with an `auth-arr` variant that skips `/api/*` (API-key clients),
  plus `AuthenticationMethod=External` in each app; qBittorrent allows the `caddy`
  subnet without its login. Possibly rename the `starrs` paths, containers and
  domains to `arrs` (`/tank/v2/starrs-*` data would have to move).
- **Jellyfin**: LDAP plugin (enable Kanidm LDAPS then; users log in with their
  POSIX password, passkeys don't work there), optional SSO plugin.
- **qui**: OIDC with Kanidm (and Dockhand, if it supports it).
- **Tailnet auto-allow** via tsidp / Tailscale whois.
- **Header spoofing**: any container on the `caddy` network can reach a gated app
  directly and send `X-Auth-Request-User`. Acceptable while all stacks are yours;
  otherwise give gated apps a network shared only with Caddy.

## 5. Backup pool on sda (2 TB SMR)

- [ ] Long SMART test (about 4 hours):
  ```nu
  sudo smartctl -t long /dev/sda
  ```
- [ ] Create a `backup` pool on sda
- [ ] Replicate snapshots with sanoid + syncoid (`services.sanoid`,
      `services.syncoid`); exclude `tank/v2/starrs-data` and
      `tank/qbittorrent-downloads`
- [ ] Optional: an off-site copy of the irreplaceable data (Immich)

## 6. Cleanup (after about a week of stability)

- [ ] Destroy the old zfs storage (cannot be undone):
  ```nu
  sudo zfs destroy -r tank/unmanaged/podman
  ```
- [ ] Remove the unused `zfs-storage-driver` block (commented out) in
      `modules/programs/podman.nix`
- [ ] Delete the volume tars you no longer need
- [ ] Destroy the old Dockge dataset (stacks were copied to
      `/tank/v2/services/dockhand/stacks`; cannot be undone):
  ```nu
  sudo zfs destroy tank/v2/services/dockge
  ```

## 7. Later

- [ ] `podman-restart` is fragile: one failing container fails the unit, and
      systemd kills the conmon of the containers it just started. Try a
      `KillMode=process` guard in `modules/programs/podman.nix` and test it.
- [ ] The pool's special vdev is a single SSD, so losing it loses all of `tank`;
      mirror it with a second SSD of at least 931 GB (`zpool attach`)
