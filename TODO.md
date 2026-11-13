# TODO

Open work on prts. Commands are nushell, run on prts unless noted. Design notes live
elsewhere: CLAUDE.md (repo, containers), `modules/hosts/prts/auth.md` (central auth, app
logins, Jellyfin LDAP).

## 1. Backup pool (2 TB SMR)

The Seagate ST2000DM005 (`ata-ST2000DM005-2U9102_WFM449L2`; it was sda, now sdb: use
the by-id name) passed the long SMART test (2026-10-10: no errors, 0
reallocated/pending sectors, about 29,600 power-on hours).

- [ ] `tank` is DEGRADED ("too many errors") since 2026-10-22: the SATA link to its
      only data disk (WD40EFZZ, ata1) dropped on 2026-10-21 and 2026-10-22 (`SError:
      PHYRdyChg 10B8B CommWake`, command timeouts, link reset). Not the media: SMART has
      0 pending/reallocated sectors and 0 CRC errors, and the 2026-11-01 scrub repaired
      nothing. Reseat or replace that disk's SATA (and power) cable, then
      `sudo zpool clear tank` and a scrub. ZFS keeps a DEGRADED vdev in use, but a
      second link drop could fault the pool's only disk.
- [x] Create the `backup` pool (2026-11-13; command in `modules/hosts/prts/backup.nix`)
- [ ] Deploy the sanoid + syncoid config (`modules/hosts/prts/backup.nix`: hourly
      snapshots of `tank`, replicated hourly to `backup/tank`; excludes
      `tank/v2/arrs-data`). The first sync sends about 240 GB.
      Then check:
  ```nu
  systemctl status sanoid syncoid-tank
  zfs list -r -o name,used backup
  zfs list -t snapshot backup/tank/v2/immich-upload
  ```
- [ ] Optional: an off-site copy of the irreplaceable data (Immich)
- [ ] Once backups run: upgrade Jellyfin from the pinned 10.11.8 to 12.x (`latest` is
      12.x now: Jellyfin dropped the "10."). One-way database migrations, so keep a
      pin, never `latest`. Steps: snapshot `/tank/v2/services/jellyfin`, uninstall
      the LDAP Authentication plugin (log in as the local `admin`), bump the image
      tag in `modules/hosts/prts/jellyfin/default.nix`, reinstall the plugin (24.0.0.0 targets
      12.0), test a Kanidm login, then run a full library scan (required: alternate
      versions are dropped until it runs). Read the 12.x release notes first.

## 2. Cleanup (after about a week of stability)

The storage migration was on 2026-10-04, the arrs move on 2026-10-10. The `zfs destroy`
commands can't be undone.

- [x] Podman's old ZFS storage `tank/unmanaged` (destroyed 2026-11-14; nothing needed
      migrating; its database and container definitions are kept in
      `/tank/v2/backups/podman-zfs-storage-2026-10-04`, may hold env secrets)
- [ ] Dockge's old data: `sudo zfs destroy tank/v2/services/dockge`
- [ ] Leftovers from the old setup: the `caddy-reverse-proxy-ingress` network. Not the
      volumes `dozzle-data` and `caddy-reverse-proxy-data`: the quadlets use them (Dozzle's
      settings, Caddy's certificates).
  ```nu
  sudo podman network rm caddy-reverse-proxy-ingress
  ```
- [x] Snapshots: the 34 `@migrate`, `@pre-localhost` and `@pre-latest` snapshots
      (destroyed 2026-11-14)
- [x] `tank/qbittorrent-downloads`: Blue Archive Collection and the Thai books moved to
      `tank/v2/archived` (checksum-verified), dataset destroyed (2026-11-14)
- [ ] The volume exports in `/tank/v2/backups/podman-volumes-2026-10-04/` (keep the
      ones listed as archives in section 5)
- [ ] The unused Kanidm service account:
      `kanidm service-account delete jellyfin_ldap -D idm_admin`

## 3. Auth follow-ups

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

## 4. Later

- [ ] Notifications: nothing on prts can alert you yet (`services.smartd` only writes
      to the journal and wall). Pick one channel (e.g. ntfy, or mail through msmtp) and
      route to it: smartd warnings, ZFS events (ZED: pool degraded, scrub results),
      failed systemd units (auto-upgrade, `podman-auto-update` rollbacks, backups once
      section 1 exists), and Arcane's update notifications.
      Auto-upgrade first (`OnFailure=` on `nixos-upgrade.service`): a failed build
      leaves prts on the old generation silently, so later merges (and security
      updates) stop deploying unnoticed, and a stalled Kanidm bump plus the next
      weekly one would skip a release, which Kanidm can't migrate. It also catches
      activation and runtime failures, which CI's build can't see.
- [ ] The pool's special vdev is a single SSD, so losing it loses all of `tank`; mirror
      it with a second SSD of at least 931 GB (`zpool attach`).

## 5. Lab projects (Arcane)

Lab projects live in `/tank/v2/services/arcane/projects/<project>/`, run by Arcane
(`arcane.songpola.dev`). Deploy and update them per project, never per container (that
pins IPs on Podman).

- [ ] Start the copied projects you still want (none are running): `cwa`, `forgejo`,
      `kay-chan-discord-bot`, `mc-all-the-mons`, `unturned-server`, `speedtest`. Update
      checks: fine for stateless ones (speedtest, cwa); careful with forgejo (one-way
      migrations) and the game servers until backups exist.
- [ ] Only if still wanted, `ite-310-wordpress` and `ite-444-full-stack` (databases
      in named volumes; create, import, then start):
  ```nu
  let b = "/tank/v2/backups/podman-volumes-2026-10-04"
  cd /tank/v2/services/arcane/projects/ite-310-wordpress
  sudo podman compose create
  sudo podman volume import ite-310-wordpress_db-data $"($b)/ite-310-wordpress_db-data.tar"
  sudo podman volume import ite-310-wordpress_wp-data $"($b)/ite-310-wordpress_wp-data.tar"
  sudo podman compose start
  # ite-444-full-stack: same, with ite-444-full-stack_dbdata (also builds an image)
  ```
- Not restored on purpose: `mystifying_agnesi`, `arcane-data`, `netnow_db-data`,
  `buildx_buildkit_default_state` (tars kept as archives). netnow is archived.
  dashbeam, protonmail-bridge and radicale are dropped; their compose files stay in
  `stacks/` as references (see `stacks/README.md`). Data: radicale in `/tank/radicale`,
  protonmail-bridge in `/tank/v2/services/protonmail-bridge/root`.
- A lab that becomes permanent moves into the repo as quadlets (like `arrs/`), with its
  secrets in sops.
