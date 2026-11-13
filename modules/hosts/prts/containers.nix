# prts containers: Podman, the Caddy reverse proxy and its ACME account, and the Nix-managed
# infrastructure containers (quadlets). The apps are in ./arrs and ./jellyfin; Arcane runs the
# lab projects (not in this repo). See ./quadlet-migration.md.
{ den, ... }:
{
  den.hosts."x86_64-linux"."prts".settings = {
    programs.podman.volume-path.path = "/tank/v2/podman-volumes";

    # Shared by Caddy and Kanidm's certificate
    security.acme-cloudflare = {
      email = "songpola@songpola.dev";
      sopsFile = ./secrets/cloudflare.secrets.yaml;
    };

    services.caddy-reverse-proxy.configDir = "/tank/v2/services/caddy-reverse-proxy/config";

    services.dozzle = {
      enableActions = true;
      domain = "dozzle.songpola.dev";
    };

    # Dockhand: off, kept as a reference; data archived in /tank/v2/backups/dockhand-2026-11-13
    # (see ./quadlet-migration.md)
    # services.dockhand = {
    #   dataDir = "/tank/v2/services/dockhand";
    #   user = "songpola";
    #   domain = "dockhand.songpola.dev";
    #   encryption-key.sopsFile = ./secrets/dockhand.secrets.yaml;
    # };

    # Lab projects only (not in this repo), in <dataDir>/projects; see ./quadlet-migration.md
    services.arcane = {
      dataDir = "/tank/v2/services/arcane";
      # Root, so it can start, stop and restart the quadlets and run auto-update over D-Bus
      user = "root";
      domain = "arcane.songpola.dev";
      encryption-key.sopsFile = ./secrets/arcane.secrets.yaml;
    };
  };

  den.aspects."prts".includes = with den.aspects; [
    programs.podman
    programs.podman.volume-path
    programs.podman.auto-update

    services.caddy-reverse-proxy
    services.dozzle
    # services.dockhand
    # services.dockhand.encryption-key
    services.arcane
    services.arcane.encryption-key
  ];
}
