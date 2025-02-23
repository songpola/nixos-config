{
  firewall = {
    allowedTCPPorts = [
      # caddy
      80
      443
      # harmonia
      # 5000
      # syncthing
      8384
    ];
    allowedUDPPorts = [
      443 # caddy: HTTP/3
    ];
  };
  hostId = "eb8b6756";
  nftables.enable = true;
  useDHCP = false;
}
