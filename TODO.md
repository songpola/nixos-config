# TODO

Remaining work after switching prts to the overlay storage driver
(graph root on the `@containers` btrfs subvolume, named volumes in
`/tank/v2/podman-volumes`). Commands are nushell, run on prts unless noted.

Volume exports are in `/tank/v2/backups/podman-volumes-2026-10-04/`.

## 1. Bring the stacks back

Stacks live in `/tank/v2/services/dockge/stacks`; deploy them from Dockhand.

- [ ] Stacks without named volumes: `cwa`, `forgejo`, `kay-chan-discord-bot`,
      `mc-all-the-mons`, `unturned-server`, `speedtest` (images are pulled again,
      so the first start is slow)
- [ ] New stacks from `modules/hosts/prts/containers/`: `dozzle-compose.yaml`
      and `protonmail-bridge-compose.yaml`
- [ ] Only if still wanted, `ite-310-wordpress` and `ite-444-full-stack`
      (databases in named volumes; create, import, then start):
  ```nu
  let b = "/tank/v2/backups/podman-volumes-2026-10-04"
  cd /tank/v2/services/dockge/stacks/ite-310-wordpress
  sudo podman compose create
  sudo podman volume import ite-310-wordpress_db-data $"($b)/ite-310-wordpress_db-data.tar"
  sudo podman volume import ite-310-wordpress_wp-data $"($b)/ite-310-wordpress_wp-data.tar"
  sudo podman compose start
  # ite-444-full-stack: same, with ite-444-full-stack_dbdata (also builds an image)
  ```
- [ ] Not restored on purpose: `mystifying_agnesi`, `arcane-data`,
      `netnow_db-data`, `buildx_buildkit_default_state` (tars kept as archives)

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

Not running, so `*.songpola.dev` is unreachable and Dockhand is published on
port 3000 instead.

- [ ] Decide how to run it (compose stack in Dockhand, or Nix) and how to handle
      the Cloudflare API token (sops is disabled)
- [ ] Restore certificates if wanted: `caddy-reverse-proxy-data.tar`
- [ ] Re-enable the Caddy labels and `networks` in `dockhand.nix`; drop its
      `ports`

## 4. Backup pool on sda (2 TB SMR)

- [ ] Long SMART test (about 4 hours):
  ```nu
  sudo smartctl -t long /dev/sda
  ```
- [ ] Create a `backup` pool on sda
- [ ] Replicate snapshots with sanoid + syncoid (`services.sanoid`,
      `services.syncoid`); exclude `tank/v2/starrs-data` and
      `tank/qbittorrent-downloads`
- [ ] Optional: an off-site copy of the irreplaceable data (Immich)

## 5. Cleanup (after about a week of stability)

- [ ] Destroy the old zfs storage (cannot be undone):
  ```nu
  sudo zfs destroy -r tank/unmanaged/podman
  ```
- [ ] Remove the unused `zfs-storage-driver` block (commented out) in
      `modules/programs/podman.nix`
- [ ] Delete the volume tars you no longer need
- [ ] Remove `dockge.nix`, `arcane.nix` (replaced by Dockhand)

## 6. Later

- [ ] `podman-restart` is fragile: one failing container fails the unit, and
      systemd kills the conmon of the containers it just started. Try a
      `KillMode=process` guard in `modules/programs/podman.nix` and test it.
- [ ] Migrate `radicale` (data under `/tank/v1/radicale`, check it exists) and
      `qui` to compose stacks; `jellyfin` once GPU access (CDI) is confirmed
- [ ] The pool's special vdev is a single SSD, so losing it loses all of `tank`;
      mirror it with a second SSD of at least 931 GB (`zpool attach`)
