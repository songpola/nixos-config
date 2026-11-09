# Quadlet migration (started 2026-11-10)

Move every long-running container on PRTS to [quadlet-nix](https://github.com/SEIAROTg/quadlet-nix)
(one systemd unit per container), and replace Dockhand with Arcane for throwaway lab
projects only. Downtime during the work is fine (single user).

## Why

- Dockhand's per-container Update recreates containers through Podman's Docker-compatible
  API with the old `IPAddress`/`MacAddress`, which Podman turns into static IP pins. Pins
  raced at boot (byparr took sonarr-anime's IP), failing `podman start --all`.
- `podman-restart.service` keeps every conmon it starts in its own cgroup (Podman skips
  the conmon scope when `$INVOCATION_ID` is set). When one container fails, systemd kills
  the unit's cgroup, leaving every container running unmonitored (`Exited (-1)` later).
  Upstream: podman-container-tools/podman#26008 (open), #29582 (maintainer: unset
  `INVOCATION_ID` when running Podman from a service).
- Podman's maintainers recommend one unit per container (Quadlet) over restart policies
  plus podman-restart. Arcane v2.17 added native Podman support, but compose projects
  still use the compat API and its single-container Redeploy/Edit still pins.

## Decisions

- quadlet-nix for everything in the repo: arrs, jellyfin (with Jikan), and the
  infrastructure now on `virtualisation.oci-containers` (caddy-reverse-proxy,
  oauth2-proxy, dozzle, and Arcane itself).
- Arcane manages a lab area only (`/tank/v2/labs`), for temporary projects not in this
  repo. Labs come back after a reboot, so podman-restart and its fix stay. Deploy labs
  at the project level only, never with a container's Redeploy/Update/Edit button.
- Arcane image pinned to a release with the Podman fixes (`cdd81797`: v2.17.4 or later),
  no D-Bus socket mounted (keeps it away from the Nix-managed units and auto-update).
- dashbeam, protonmail-bridge and radicale are dropped (none were deployed); their
  compose files stay in `stacks/` as references.

## Phases

### 0. Stabilise and shrink

- [x] `modules/programs/podman.nix`: keep `podman-restart.environment.INVOCATION_ID = ""`
      (now referencing upstream), add `podman-restart.restartIfChanged = false` (its
      `ExecStop` stops every container, so a changed unit on switch, e.g. a Podman bump,
      stopped them all).
- [x] Mark dashbeam, protonmail-bridge and radicale as references (`stacks/README.md`),
      drop their TODO entries.
- [ ] Commit, deploy. The new unit has `X-RestartIfChanged=false`, so the switch leaves
      podman-restart alone: apply the fix with a reboot (or
      `sudo systemctl restart podman-restart`, which stops every container first).

### 1. quadlet-nix foundation

- [ ] `flake-file.inputs.quadlet-nix`, `nix run .#write-flake`; a `programs.quadlet`
      aspect (the removed one in `d6e629ba` is a starting point).
- [ ] Check: whether quadlet-nix owns `/etc/containers/systemd` (hand-written lab
      quadlets), its auto-update option, its unit names (for the `zfs-mount` ordering in
      podman.nix).
- [ ] `caddy` network as `virtualisation.quadlet.networks.caddy` (same name and subnet
      `10.89.1.0/24`), exposed by `services.caddy-reverse-proxy`, replacing
      `podman-network-caddy.service`.
- [ ] podman.nix: `zfs-mount` ordering and `meta.autoUpdateLabels` for quadlet units.

### 2. Infrastructure to quadlet-nix

- [ ] caddy-reverse-proxy, oauth2-proxy, dozzle (and its variants), one at a time; the
      `caddy-sites` quirk and labels move with them.
- [ ] Drop the oci-containers branch of the podman.nix ordering once none are left
      (Dockhand stays on oci-containers until phase 5).

### 3. arrs to quadlet-nix

- [ ] Aspect with the arrs, qBittorrent, qui, clonarr, byparr: an `arrs` network plus
      `caddy` for exposed apps, same bind mounts and `/mnt/starrs-data` paths, songpola:users,
      health checks with `Notify=healthy`, `Requires`/`After` for `depends_on`. `arrs.md`
      and the Prowlarr definitions move next to it.
- [ ] Cutover: `docker compose down` of the Dockhand stack, switch, check no static IPs,
      remove the stack from Dockhand, delete `stacks/arrs/`.

### 4. jellyfin and Jikan to quadlet-nix

- [ ] Same pattern, GPU through CDI (`nvidia.com/gpu=all`), `JIKAN_APP_KEY` and
      `JIKAN_TYPESENSE_API_KEY` from sops instead of Dockhand stack variables.
- [ ] Same cutover; delete `stacks/jellyfin/`.

### 5. Arcane for labs, replacing Dockhand

- [ ] `services.arcane` aspect on quadlet-nix: pinned image, Podman socket (no D-Bus),
      `/app/data`, labs directory at the same path inside and out, forward-auth, sops
      encryption key (`ARCANE_ENCRYPTION_KEY_FILE`), Kanidm OIDC client (verify the
      callback path), `ARCANE_APP_URL`, `ARCANE_TRUSTED_PROXIES`.
- [ ] Move or drop the Dockhand-only stacks (cwa, forgejo, ite-310-wordpress,
      ite-444-full-stack, kay-chan-discord-bot, mc-all-the-mons, netnow, speedtest,
      unturned-server).
- [ ] Remove Dockhand: aspect, Kanidm client and secrets, `dockhand.update` label;
      archive `/tank/v2/services/dockhand` after a few weeks.

### 6. Docs and verification

- [ ] CLAUDE.md (prts: Quadlet for the repo's containers, Arcane for labs, no Git stacks),
      `auth.md`, TODO.md, `containers.nix` header.
- [ ] Reboot test: every quadlet unit active, podman-restart `active (exited)`,
      `systemctl --failed` empty, no `static_ips` in the Podman DB, next nightly upgrade
      passes.
