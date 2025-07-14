{
  lib,
  config,
  namespace,
  ...
}:
lib.${namespace}.mkPresetModule config [ "services" "tailscale" ] {
  systemConfig = [
    {
      services.tailscale = {
        enable = true;
        openFirewall = true;
        useRoutingFeatures = "server";
        extraSetFlags = [
          "--operator=${namespace}"
          # Tailscale SSH is not compatible with Podman yet
          # (mkIf (!config.${namespace}.containers.podman.enable) "--ssh")
        ];
      };
    }
  ];
}
