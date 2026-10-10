# TODO

Open work on prts. Commands are nushell, run on prts unless noted. Design notes live
elsewhere: CLAUDE.md (repo, stacks), `modules/hosts/prts/auth.md` (central auth, app
logins, Jellyfin LDAP).

## 1. Stacks

Stacks in `modules/hosts/prts/stacks/` are Git stacks in Dockhand (repo
`https://github.com/songpola/nixos-config`, branch `main`, compose path
`modules/hosts/prts/stacks/<stack>/compose.yaml`, env panel left empty, scheduled sync
daily at 05:00). The others live only in `/tank/v2/services/dockhand/stacks`.

- [ ] Start the Dockhand-only stacks (none are running): `cwa`, `forgejo`,
      `kay-chan-discord-bot`, `mc-all-the-mons`, `unturned-server`, `speedtest`.
      Auto-update per container: on for stateless ones (speedtest, cwa); check-only
      for forgejo (one-way migrations) and the game servers until backups exist.
- [ ] Add `protonmail-bridge` as a Git stack (data in
      `/tank/v2/services/protonmail-bridge/root`; if empty, log the bridge in once
      through its CLI in the container).
- [ ] Only if still wanted, `ite-310-wordpress` and `ite-444-full-stack` (databases
      in named volumes; create, import, then start):
  ```nu
  let b = "/tank/v2/backups/podman-volumes-2026-10-04"
  cd /tank/v2/services/dockhand/stacks/ite-310-wordpress
  sudo podman compose create
  sudo podman volume import ite-310-wordpress_db-data $"($b)/ite-310-wordpress_db-data.tar"
  sudo podman volume import ite-310-wordpress_wp-data $"($b)/ite-310-wordpress_wp-data.tar"
  sudo podman compose start
  # ite-444-full-stack: same, with ite-444-full-stack_dbdata (also builds an image)
  ```
- Not restored on purpose: `mystifying_agnesi`, `arcane-data`, `netnow_db-data`,
  `buildx_buildkit_default_state` (tars kept as archives). Radicale is dropped;
  `stacks/radicale/compose.yaml` stays as a reference, its data is in `/tank/radicale`.
- Later, optionally: move the other stacks into the repo, with their secrets out of
  `.env` (Dockhand secret variables, or 1Password `op://` references: provider in
  Settings → Secrets, a read-only service account on a dedicated vault, `${VAR:?}` in
  compose so a missing secret stops the deploy). Test once that `op://` references in a
  Git stack's `.env` resolve.

## 2. Verify

- [ ] Restart on boot works: reboot, or `sudo systemctl restart podman-restart`
      (briefly stops every container); expect `active (exited)` and every
      container back in `sudo podman ps`

## 3. Backup pool on sda (2 TB SMR)

sda passed the long SMART test (2026-10-10: no errors, 0 reallocated/pending sectors,
about 29,600 power-on hours).

- [ ] Create a `backup` pool on sda
- [ ] Snapshots and replication with sanoid + syncoid (`services.sanoid`,
      `services.syncoid`); exclude `tank/v2/arrs-data` and `tank/qbittorrent-downloads`
- [ ] Optional: an off-site copy of the irreplaceable data (Immich)

## 4. Cleanup (after about a week of stability)

The storage migration was on 2026-10-04, the arrs move on 2026-10-10. The `zfs destroy`
commands can't be undone.

- [ ] Old storage and Dockge:
  ```nu
  sudo zfs destroy -r tank/unmanaged/podman
  sudo zfs destroy tank/v2/services/dockge
  ```
  Then remove the commented-out `zfs-storage-driver` block in
  `modules/programs/podman.nix`.
- [ ] Leftovers from the old setup: the `caddy-reverse-proxy-ingress` network, the
      orphaned volumes `dozzle-data` and `caddy-reverse-proxy-data` (Caddy's
      certificates are reissued by the Nix-managed Caddy), and the
      `compose.yaml.bak` files in the Dockhand stacks:
  ```nu
  sudo podman network rm caddy-reverse-proxy-ingress
  sudo podman volume rm dozzle-data caddy-reverse-proxy-data
  sudo rm /tank/v2/services/dockhand/stacks/*/compose.yaml.bak
  ```
- [ ] Snapshots: the `@migrate` snapshots across `tank` (biggest:
      `tank/v2/arrs-data@migrate`, `tank/qbittorrent-downloads@migrate`) and
      `tank/v2/services/arrs@pre-localhost` / `@pre-latest`:
  ```nu
  zfs list -t snapshot -o name,used | lines | where $it =~ '@(migrate|pre-localhost|pre-latest)'
  ```
- [ ] The volume exports in `/tank/v2/backups/podman-volumes-2026-10-04/` (keep the
      ones listed as archives in section 1)
- [ ] The unused Kanidm service account:
      `kanidm service-account delete jellyfin_ldap -D idm_admin`

## 5. Auth follow-ups

- **Sharing PRTS with a friend**: Tailscale node sharing, not public access. Before
  sharing, limit shared users (`autogroup:shared`) to port 443 in the Tailscale ACL:
  Kanidm listens on 8443 and 636 on all addresses, and Tailscale accepts everything on
  `tailscale0`. Then: a Kanidm person in `prts_media` only (`auth.nix`), POSIX
  attributes and password (see `auth.md`), and Jellyfin creates their account on first
  login.
- **Real client IPs behind Caddy** (deferred on purpose, 2026-10-09): Caddy and
  everything behind it see every client as `10.89.1.1`. Harmless while access is
  identity-based; fix it before anything that relies on the client IP: tailnet
  auto-allow (whois), IP rules or allowlists in Caddy, fail2ban/CrowdSec, per-IP rate
  limits, or apps' "local network" settings (arrs' "disabled for local addresses",
  Jellyfin's LAN networks: today every client counts as local).
  Cause (checked): netavark DNATs 80/443 to Caddy, so the packets are forwarded, not
  input; Tailscale's `ts-forward` marks everything forwarded from `tailscale0`
  (`0x40000`) and `ts-postrouting` masquerades it to the outgoing interface's address,
  the bridge's `10.89.1.1`. Not `--snat-subnet-routes=false`: it also drops the
  masquerade for the subnet route (`10.0.0.0/16`) and exit-node traffic, breaking both.
  Proposed fix (untested), e.g. in `modules/programs/podman.nix` when Tailscale routes:
  clear Tailscale's mark on traffic into Podman bridges before its masquerade runs;
  subnet-route and exit-node traffic leaves on `eno1` and is still masqueraded.
  ```nft
  table inet tailscale-podman {
    chain postrouting {
      type filter hook postrouting priority srcnat - 1;
      oifname "podman*" meta mark set meta mark & 0xff00ffff
    }
  }
  ```
  Replies need nothing extra: the container's default route is the host, which routes
  `100.x` out `tailscale0`, and conntrack undoes the DNAT.
- **Header spoofing / direct access**: any container on the `caddy` network can reach a
  gated app directly (the arrs, qBittorrent and qui trust that network). Acceptable
  while all stacks are yours; otherwise give gated apps a network shared only with Caddy.
- **Tailnet auto-allow** via tsidp / Tailscale whois (needs real client IPs).
- **Dashboard at `home.songpola.dev`**, behind `import auth`; it could read
  `X-Auth-Request-Groups` to show links per group (Kanidm's own app list is at
  `idm.songpola.dev/ui/apps`).

## 6. Later

- [ ] Notifications: nothing on prts can alert you yet (`services.smartd` only writes
      to the journal and wall). Pick one channel (e.g. ntfy, or mail through msmtp) and
      route to it: smartd warnings, ZFS events (ZED: pool degraded, scrub results),
      failed systemd units (auto-upgrade, `podman-auto-update` rollbacks, backups once
      section 3 exists), and Dockhand's update notifications.
- [ ] `podman-restart` is fragile: one failing container fails the unit, and systemd
      kills the conmon of the containers it just started. Try a `KillMode=process`
      guard in `modules/programs/podman.nix` and test it.
- [ ] The pool's special vdev is a single SSD, so losing it loses all of `tank`; mirror
      it with a second SSD of at least 931 GB (`zpool attach`).
