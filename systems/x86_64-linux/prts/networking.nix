{
  networking = {
    useDHCP = false;
    nftables.enable = true;
    firewall = {
      allowedTCPPorts = [
        # caddy
        80
        443
        # syncthing
        8384
      ];
      allowedUDPPorts = [
        443 # caddy: HTTP/3
      ];
    };
  };
  systemd.network = {
    enable = true;
    netdevs = {
      "10-br0" = {
        netdevConfig = {
          Name = "br0";
          Kind = "bridge";
          MACAddress = "none";
        };
      };
    };
    networks = {
      "20-br0" = {
        matchConfig.Name = "br0";
        networkConfig = {
          DHCP = "yes";
          UseDomains = "yes";
        };
        linkConfig.RequiredForOnline = "routable";
      };
      "30-eno1" = {
        matchConfig.Name = "eno1";
        networkConfig.Bridge = "br0";
        linkConfig.RequiredForOnline = "enslaved";
      };
    };
    links = {
      "40-br0" = {
        matchConfig.OriginalName = "br0";
        linkConfig.MACAddressPolicy = "none";
      };
    };
  };
}
