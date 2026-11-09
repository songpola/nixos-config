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
- [x] Commit, deploy (done 2026-11-10, rebooted: podman-restart `active`, each conmon in
      its own `libpod-conmon-*` scope, nothing failed). The new unit has `X-RestartIfChanged=false`, so the switch leaves
      podman-restart alone: apply the fix with a reboot (or
      `sudo systemctl restart podman-restart`, which stops every container first).

### 1. quadlet-nix foundation

- [x] `flake-file.inputs.quadlet-nix`, `nix run .#write-flake`; `programs.quadlet` aspect
      (`modules/programs/quadlet.nix`).
- [x] Checked: quadlet-nix writes one `environment.etc` file per unit into
      `/etc/containers/systemd/`, not the directory, so hand-written lab quadlets can sit
      next to them. Its `autoUpdate.enable` replaces the `podman-auto-update` timer's
      schedule: leave it off, keep `programs.podman`'s labels and timer. Unit names:
      `<name>.service` (container), `<name>-network.service` (network, Podman name = attr
      name), `<name>-volume.service`.
- [x] `caddy` network as `virtualisation.quadlet.networks.caddy` (subnet pinned to
      `10.89.1.0/24`, setting `services.caddy-reverse-proxy.subnet`), replacing
      `podman-network-caddy.service`; the oci-containers and podman-restart order after
      `caddy-network.service`. Quadlet creates it with `--ignore`, so the live network is kept.
- [x] `zfs-mount` ordering for quadlet containers lives in `programs.quadlet`.
- [x] Deploy and check (2026-11-10): `caddy-network.service` active, the network kept
      (created 2026-10-05, same subnet), every site behind Caddy answering.

### 2. Infrastructure to quadlet-nix

- [x] caddy-reverse-proxy, oauth2-proxy, dozzle (deployed 2026-11-10). Naming: the Nix
      attribute (= Quadlet file) is `quadlet-<name>`, asserted in `programs.quadlet`, so units
      are `quadlet-<name>[-network|-volume|-pod].service`; Podman names stay plain (`caddy`,
      `dozzle`), so compose still joins with `networks: [caddy]`. quadlet-nix can't set
      `ServiceName=`, so the unit prefix needs the attribute prefix.
      Gotcha: `%` in any value must be `%%` (systemd specifiers), e.g. URL-encoded icons.
- [ ] Drop the oci-containers branch of the podman.nix ordering once none are left
      (Dockhand stays on oci-containers until phase 5).

### 3. arrs to quadlet-nix

- [x] `modules/hosts/prts/arrs/` (with `arrs.md`, the Prowlarr definitions and the Dozzle
      icons): network `arrs` (quadlet `quadlet-arrs`), each app aliased there by its old
      compose service name (`Network=quadlet-arrs.network:alias=<service>`), web UIs also on
      `caddy` behind the gate; same container names, bind mounts and `/mnt/starrs-data`.
      No health checks or `depends_on` existed, so none added; qui's allowed CIDR now comes
      from `services.caddy-reverse-proxy.subnet`.
- [x] Cutover (2026-11-10): arrs stack deleted in Dockhand (removed its containers and
      `arrs_default`), `stacks/arrs/` deleted, switch. All 9 units active, no `static_ips`
      in the Podman DB, the stored links resolve (prowlarr → byparr:8191, sonarr →
      qbittorrent:8080, radarr → prowlarr:9696, qui → qbittorrent:8080), every site gated.

### 4. jellyfin and Jikan to quadlet-nix

- [x] `modules/hosts/prts/jellyfin/`: jellyfin, jikan, jikan-mongodb, jikan-typesense
      (units `quadlet-jellyfin*`), networks `jikan` (internal) and `jikan-egress` (Jikan's
      internet), GPU through CDI, the compose volumes reused by name
      (`jellyfin_jikan-mongodb`, `jellyfin_jikan-typesense`, so the index is kept). Keys in
      `secrets/jellyfin.secrets.yaml` (`jikan/APP_KEY`, `jikan/TYPESENSE_API_KEY`), taken
      from the old container's environment. `stacks/jellyfin/` deleted. arrs units renamed
      `quadlet-arrs-<service>`, containers `arrs-<service>` (qui's is now `arrs-qui`; the
      others reach it by its `qui` alias).
- [ ] Cutover: delete the jellyfin stack in Dockhand (keep its volumes), switch, check.

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
