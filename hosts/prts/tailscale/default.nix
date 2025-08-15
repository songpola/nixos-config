{ delib, ... }:
delib.host {
  name = "prts";

  myconfig.tailscale.enable = true;

  nixos.services.tailscale = {
    useRoutingFeatures = "server";
    extraSetFlags = [
      "--advertise-routes=10.0.0.0/16"
      "--advertise-exit-node"
    ];
  };
}
