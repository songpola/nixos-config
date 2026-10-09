# TODO

Remaining work on prts after switching to the overlay storage driver (graph root
on the `@containers` btrfs subvolume, named volumes in `/tank/v2/podman-volumes`),
plus the planned central auth (section 4). Commands are nushell, run on prts
unless noted.

Volume exports are in `/tank/v2/backups/podman-volumes-2026-10-04/`.

## 1. Bring the stacks back

Stacks in `modules/hosts/prts/stacks/` are Git stacks in Dockhand (the repo is
the source of truth, see CLAUDE.md); the others live in
`/tank/v2/services/dockhand/stacks`. Deploy both from Dockhand.

- [ ] Stacks without named volumes: `cwa`, `forgejo`, `kay-chan-discord-bot`,
      `mc-all-the-mons`, `unturned-server`, `speedtest` (images are pulled again,
      so the first start is slow)
- [ ] Remove the `dozzle` stack in Dockhand (Dozzle now runs from Nix:
      `services.dozzle`; its old volume `dozzle_dozzle-data` is empty)
- [ ] Git stacks from `modules/hosts/prts/stacks/`: `arrs` (formerly
      "starrs"; includes qui), `jellyfin` (check the GPU is visible:
      `nvidia-smi` in the container), `protonmail-bridge`. Push `main` first:
      Dockhand deploys what is there. In Dockhand, per stack:
      - Settings → Git: add `https://github.com/songpola/nixos-config` once
        (public, no credentials).
      - New Git stack: branch `main`, compose path
        `modules/hosts/prts/stacks/<stack>/compose.yaml` (its `.env` is picked
        up automatically; leave the env panel empty, no "Populate"), scheduled
        sync daily at 05:00 (after the 04:00 NixOS auto-upgrade, which a
        stack's change may depend on; no webhook, Dockhand is Tailscale-only).
      - `arrs` is already deployed as an internal stack: delete that one first
        (container names are fixed; data is in bind mounts, nothing is lost),
        then add it as a Git stack.
      Later: optionally move the other stacks into the repo too, with their
      secrets out of `.env` (Dockhand secret variables, or 1Password `op://`
      references: provider in Settings → Secrets, a read-only service account
      on a dedicated vault, `${VAR:?}` in compose so a missing secret stops the
      deploy). Data
      moved 2026-10-10 (`tank/v2/arrs-data`, `tank/v2/services/arrs/<app>`,
      `@migrate` snapshots kept; qui is a plain directory now, not a dataset).
      The stack no longer shares one network namespace (the pod-style `arrs`
      pause container is gone): every app is its own container on the stack's
      network, containers are `arrs-*`, and domains drop the prefix
      (`sonarr.songpola.dev`, `qbit.songpola.dev`, ...).
      - [x] The apps' stored links point at service names instead of the old
        container names (`starrs-prowlarr:9696` → `prowlarr:9696`,
        `starrs-qbittorrent` → `qbittorrent`, qui's `starrs:8080` →
        `qbittorrent:8080`, ...): Sonarr/Radarr indexers and download clients
        (renamed `qbittorrent`), Prowlarr's apps, download client and Byparr
        proxy, qui, `clonarr.json` (done 2026-10-10). Delete the
        `tank/v2/services/arrs@pre-localhost` snapshot once the stack works.
      - [ ] After the first start, test Prowlarr's apps and the
        indexers/download clients in each app (all should be green).
      Container paths stay `/mnt/starrs-data` on purpose (the apps store them in
      their databases).
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

Status (2026-10-09): steps 1-6 are deployed on prts and verified (Kanidm's
Let's Encrypt certificate, `idm` / `auth` through Caddy, the gate on Dockhand and
Dozzle for `prts_admins`, "Verify" 1-3, Dockhand SSO); step 7 is written. What's
left is under "Later".

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
  (no env-file template). Done as the `security.acme-cloudflare` aspect: it
  declares the secret once and sets `security.acme.defaults` (email, DNS
  provider, token), which Kanidm's certificate inherits and Caddy reads.
- Caddy runs in a container, Kanidm on the host: Caddy proxies to
  `https://host.containers.internal:8443` (checked: that is `10.89.1.1`, the
  `caddy` network's bridge gateway). Kanidm binds `0.0.0.0:8443`; the firewall
  allows 8443 from `podman*` interfaces (wildcard, bridge names are dynamic; like
  the DNS rule in `modules/programs/podman.nix`). The LAN stays blocked, but
  Tailscale accepts everything arriving on `tailscale0`, so the tailnet can reach
  8443 directly; fine for an IdP with its own TLS.
- Storage: database stays at `/var/lib/kanidm` on the root SSD (path is fixed by
  the module), default `db_fs_type`. Kanidm starts after `zfs-mount.service`
  but doesn't require it, so login survives a failed pool import. Online backups go to `/tank/v2/services/kanidm/backups` so ZFS
  snapshots and the planned syncoid replication cover them.
- LDAP stays off until an app needs it.
- Tailnet auto-allow / tsidp: deferred.
- **Lock-out risk:** with Dockhand and Dozzle behind Kanidm and oauth2-proxy, an
  outage of those two locks you out of the tools you would use to debug it.
  Break-glass is SSH (Tailscale SSH) plus isd. Do not use the `port` option of
  `services.dockhand` / `services.dozzle` as one: a published port skips the
  gate for anyone on the tailnet.

### Steps

1. [x] **Secrets move.** `modules/hosts/prts/secrets/cloudflare.secrets.yaml`
   with the key `cloudflare/API_TOKEN` (renamed, checked), passed to
   `security.acme-cloudflare` through settings. `secrets/auth.secrets.yaml`
   (oauth2-proxy client secret shared with Kanidm provisioning, cookie secret,
   optionally the `admin` / `idm_admin` passwords) is created in step 4.
2. [x] **Caddy** (`services.caddy-reverse-proxy`): other aspects extend it through
   quirks (done): `caddy-snippets` (Caddyfile text after the global options) and
   `caddy-sites` (sites for upstreams outside the network; each domain also
   becomes a network alias of the proxy). Not settings: those are only set by the
   host, so other aspects can't add to them.
   - [x] The `(auth)` snippet comes from the oauth2-proxy aspect (step 4) as
     `caddy-snippets`: `forward_auth` to `oauth2-proxy:4180` at
     `/oauth2/auth?allowed_groups={args[0]}`, 401 redirects to
     `https://auth.songpola.dev/oauth2/start?rd=...`; `copy_headers` replaces
     client-supplied `X-Auth-Request-*` (no `request_header`: it runs after
     `forward_auth`). Apps opt in with `caddy.import: auth <group>`.
   - [x] Kanidm's site block and the `idm.songpola.dev` network alias come from
     its `caddy-sites` entry, so containers on `caddy` resolve it to Caddy
     directly instead of looping through the host's Tailscale IP (see "Verify" 1).
3. [x] **`services.kanidm`** (new aspect, native): settings `version`,
   `domain`, `port`, `backupDir`, `backupVersions`; ACME certificate; firewall
   rule; `caddy-sites` entry for `idm.songpola.dev`. LDAP is left out until
   needed. Deployed, passkey enrolled.
4. [x] **`services.oauth2-proxy`** (`modules/services/oauth2-proxy.nix`, container
   on `caddy`): Kanidm OIDC with PKCE S256, cookie and redirect whitelist
   `.songpola.dev`, `--set-xauthrequest`, `static://202` upstream. Secrets
   (`oauth2-proxy/CLIENT_SECRET`, `oauth2-proxy/COOKIE_SECRET`) from
   `secrets/auth.secrets.yaml` through a sops env template. prts wires it with
   Kanidm in `modules/hosts/prts/auth.nix`: OIDC client `oauth2-proxy`
   (`preferShortUsername`, scope maps for both prts groups, same client secret
   as `basicSecretFile`). The landing page of `auth.songpola.dev` is an empty
   202 until a site is gated (or the dashboard exists).
5. [x] **Kanidm provisioning** (`modules/hosts/prts/auth.nix`): person
   `songpola` (in `prts_admins` and `prts_media`), both groups; the
   `admin` / `idm_admin` passwords come from `secrets/auth.secrets.yaml` (without
   them provisioning resets idm_admin on every start). The OIDC client
   `oauth2-proxy` came with step 4. Not added to built-in groups. After
   deploying: `kanidm person credential create-reset-token songpola -D idm_admin`
   and enroll the passkey.
6. [x] **Apps (only these for now).** `forward-auth` sub-aspects on
   `services.dozzle` and `services.dockhand` (group from settings; they assert
   a domain and no published port). Dozzle runs in forward-proxy mode with
   user/name from `X-Auth-Request-Preferred-Username`, email from
   `X-Auth-Request-Email`, logout to oauth2-proxy's `sign_out`; no roles header,
   so it grants all roles. Dockhand is only gated: it supports OIDC in the free
   edition, but configured in its UI (stored in its database), and its local
   login can be hidden with `DISABLE_LOCAL_LOGIN` (still at `/login?local=1`).
   Decide after testing: leave Dockhand's own auth as a second layer, turn it
   off, or add a Kanidm client `dockhand` (redirect
   `/api/auth/oidc/callback`, scopes `openid profile email`, username from
   `preferred_username`; the manual doesn't say whether it does PKCE). The free
   edition makes every user an admin, so its login only adds audit identity.
   Recommended: OIDC with `OIDC_AUTOLOGIN` + `DISABLE_LOCAL_LOGIN`.
   - [x] Kanidm client `dockhand` (PKCE S256, scope map for `prts_admins`,
     secret `dockhand/OIDC_CLIENT_SECRET` in `secrets/auth.secrets.yaml`), the
     `services.dockhand.sso-login` sub-aspect, and the provider in Dockhand's
     UI. Sign-in through Kanidm confirmed working (2026-10-09).
   - [x] Matched to the infra (from the manual): `ORIGIN`,
     `TRUST_FORWARDED_HEADERS` (only without a published port),
     `HOST_DOCKER_SOCKET` for scanner containers, and `dockhand.update=false`
     on the Nix-managed containers (`programs.podman.meta.autoUpdateLabels`).
     Confirmed in Dockhand 1.0.51's code: both container auto-update and the
     scheduled update check skip containers with the label.
   - [x] `ENCRYPTION_KEY` from sops (`services.dockhand.encryption-key`, key
     `dockhand/ENCRYPTION_KEY` in `secrets/dockhand.secrets.yaml`). Deployed:
     Dockhand logged "Using ENCRYPTION_KEY from environment, removed key file".
     (Dockhand reads it as base64 of 32 bytes; a different key re-encrypts the
     stored credentials instead of losing them.)
   - [x] Scheduled update check in Dockhand (PRTS environment → Updates), daily
     at 05:30: after the 04:00 NixOS auto-upgrade (which may restart Dockhand
     or reboot) and the 05:00 Git stack sync. No minimum image age
     (`MINIMUM_RELEASE_AGE_HOURS`, decided not to use it).
7. [x] **Version bump**, in `update-flake-lock.yml` instead of a separate
   workflow: when the updated nixpkgs has `kanidmWithSecretProvisioning_1_<n+1>`,
   the same PR bumps `version` in `modules/hosts/prts/auth.nix` (one release per
   run; title "flake.lock: update, Kanidm 1.<n+1>"); the workflow builds prts
   with both. A separate PR off `main` couldn't see the new release while the
   flake.lock PR is open, so an unmerged lock PR past the 30-day EOL would have
   left both stuck. Dry-run checked locally (1_10 → 1_11; 1_11 stays).

### Open questions

- **Group names**: decided: `prts_admins` and `prts_media`. Gate apps with these,
  not Kanidm's built-in groups (`idm_admins` etc. grant Kanidm admin rights, not
  app access).

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
   (only matters if IP-based rules are added later). **Fails**: every request,
   from the browser too, shows `10.89.1.1` (the `caddy` network's gateway).
   Cause (checked): netavark DNATs ports 80/443 to Caddy, so the packets are
   forwarded, not input; Tailscale's `ts-forward` marks everything forwarded
   from `tailscale0` (`0x40000`) and `ts-postrouting` masquerades it to the
   outgoing interface's address, the bridge's `10.89.1.1`. Not
   `--snat-subnet-routes=false`: it drops that masquerade for the subnet route
   (`10.0.0.0/16`) and exit-node traffic too, which would break both. Proposed
   fix (untested), e.g. in `modules/programs/podman.nix` when Tailscale routes:
   clear Tailscale's mark on traffic into Podman bridges before its masquerade
   runs, so only that traffic keeps its source; subnet-route and exit-node
   traffic leaves on `eno1` and is still masqueraded.
   ```nft
   table inet tailscale-podman {
     chain postrouting {
       type filter hook postrouting priority srcnat - 1;
       oifname "podman*" meta mark set meta mark & 0xff00ffff
     }
   }
   ```
   Replies need nothing extra: the container's default route is the host, which
   routes `100.x` out `tailscale0`, and conntrack undoes the DNAT. Afterwards
   every container on `caddy` sees real `100.x` addresses.
5. Whether Dockhand supports OIDC.

Checked on prts (2026-10-09): 1 (from the `caddy` network, `idm.songpola.dev`
resolves to Caddy), 2 and 3 (requests with a session pass
`allowed_groups=prts_admins@idm.songpola.dev`, others get the login redirect),
5 (yes, step 6).

### Later

- **Dashboard at `home.songpola.dev`**, behind `import auth`; the `.songpola.dev`
  cookie already covers it. It could read `X-Auth-Request-Groups` to show links
  per group; Kanidm's own app list is at `idm.songpola.dev/ui/apps`.
- **arrs stack**: every web UI is gated with `import auth prts_admins@…`
  (written 2026-10-10); Sonarr/Radarr/Prowlarr use `<APP>__AUTH__METHOD=External`
  (checked in a throwaway Sonarr: UI without login, API still needs its key).
  - [ ] qBittorrent: Options → Web UI → "Bypass authentication for clients in
    whitelisted IP subnets": `10.89.1.0/24` (the `caddy` network; not pinned in
    Nix, so if it is ever recreated with another subnet, qBittorrent just asks
    for its login again).
  - qui keeps its own login until it signs in through Kanidm (below). Clonarr
    has no login of its own; the gate is its only protection.
  The apps reach each other on the stack network, never through Caddy, so plain
  `auth` is enough. Only API clients from outside (phone apps like nzb360 or
  LunaSea, calendar feeds) would need an `auth-arr` variant that skips `/api/*`
  and `/feed/*` (the apps check API keys there). Renamed from "starrs" except
  the container path (`/mnt/starrs-data`).
- **Jellyfin**: LDAP plugin (enable Kanidm LDAPS then; users log in with their
  POSIX password, passkeys don't work there), optional SSO plugin. Its LAN
  networks see every client as local, see "Real client IPs behind Caddy".
- **qui**: OIDC with Kanidm (and Dockhand, if it supports it).
- **Tailnet auto-allow** via tsidp / Tailscale whois (needs real client IPs,
  see below).
- **Real client IPs behind Caddy** (deferred on purpose, 2026-10-09): Caddy and
  everything behind it see every client as `10.89.1.1`, Tailscale's masquerade
  (cause and proposed fix in "Verify" 4). Harmless while access is
  identity-based; fix it before anything that relies on the client IP: tailnet
  auto-allow (whois), IP rules or allowlists in Caddy, fail2ban/CrowdSec, per-IP
  rate limits, or apps' "local network" settings (arrs' "disabled for local
  addresses", Jellyfin's LAN networks: today every client counts as local).
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
      `services.syncoid`); exclude `tank/v2/arrs-data` and
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
- [ ] Notifications: nothing on prts can alert you yet. `services.smartd` only
      writes to the journal and wall (no mail). Pick one channel (e.g. ntfy, or
      mail through msmtp) and route to it: smartd warnings, ZFS events (ZED:
      pool degraded, scrub results), failed systemd units (auto-upgrade,
      `podman-auto-update` rollbacks, backups once section 5 exists), and
      Dockhand's update notifications.
