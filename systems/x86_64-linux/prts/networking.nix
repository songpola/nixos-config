{
  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    netdevs = {
      # Create the bridge interface
      "20-br0" = {
        netdevConfig = {
          Name = "br0";
          Kind = "bridge";
        };
      };
    };
    networks = {
      # Connect the bridge ports to the bridge
      "30-enp1s0" = {
        matchConfig.Name = "enp1s0"; # vm-qemu
        networkConfig.Bridge = "br0";
        linkConfig.RequiredForOnline = "enslaved";
      };
      # Configure the bridge for its desired function
      "40-br0" = {
        matchConfig.Name = "br0";
        # bridgeConfig = {};
        networkConfig.DHCP = "yes";
        # networkConfig.LinkLocalAddressing = "no"; # Disable address autoconfig when no IP configuration is required
        linkConfig.RequiredForOnline = "carrier"; # or "routable" with IP addresses configured
      };
    };
  };
}
