{
  lib,
  config,
  namespace,
  ...
}:
lib.${namespace}.mkPresetModule config [ "tailscale" ] {
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
