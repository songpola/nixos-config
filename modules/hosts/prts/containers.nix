# prts containers: Podman, the Caddy reverse proxy and its ACME account, and the Nix-managed
# infrastructure containers. Application stacks are managed by Dockhand (copies in stacks/).
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

    services.dockhand = {
      dataDir = "/tank/v2/services/dockhand";
      user = "songpola";
      domain = "dockhand.songpola.dev";
    };

    services.dozzle = {
      enableActions = true;
      domain = "dozzle.songpola.dev";
    };
  };

  den.aspects."prts".includes = with den.aspects; [
    programs.podman
    programs.podman.volume-path
    programs.podman.auto-update

    services.caddy-reverse-proxy
    services.dockhand
    services.dozzle
  ];
}
