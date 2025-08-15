{ delib, ... }:
let
  bridgeInterfaces = [ "eno1" ];
in
delib.host {
  name = "prts";

  nixos = {
    # These are defaulted to true by nixos-facter-modules
    networking = {
      useDHCP = false;
      useNetworkd = false;
    };

    systemd.network = {
      enable = true;
      netdevs."25-br0" = {
        netdevConfig = {
          Name = "br0";
          Kind = "bridge";
          MACAddress = "b4:2e:99:91:b1:10"; # eno1
        };
      };
      networks = {
        "25-br0" = {
          matchConfig.Name = "br0";
          networkConfig = {
            DHCP = "yes";
            UseDomains = "yes";
          };
          linkConfig.RequiredForOnline = "routable";
        };
        "25-br0-interfaces" = {
          matchConfig.Name = bridgeInterfaces;
          networkConfig.Bridge = "br0";
          linkConfig.RequiredForOnline = "enslaved";
        };
      };
      links."25-br0" = {
        matchConfig.OriginalName = "br0";
        linkConfig.MACAddressPolicy = "none";
      };
    };
  };
}
