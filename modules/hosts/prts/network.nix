# prts networking: systemd-networkd bridge on eno1, Tailscale (subnet router, exit node, SSH).
{ den, ... }:
{
  den.hosts."x86_64-linux"."prts".settings = {
    networking.networkd-bridge.macAddress = "b4:2e:99:91:b1:10"; # eno1

    services.tailscale = {
      optimizeUdpInterface = "eno1";
      openFirewall = true;
      operator = "songpola";
      ssh = true;
      advertiseRoutes = [ "10.0.0.0/16" ];
      advertiseExitNode = true;
    };
  };

  den.aspects."prts".includes = with den.aspects; [
    networking.networkd-bridge
    services.tailscale
  ];
}
