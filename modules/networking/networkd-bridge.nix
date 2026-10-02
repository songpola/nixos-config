{ lib, ... }:
{
  # Reference: https://wiki.archlinux.org/title/Systemd-networkd#Network_bridge_with_DHCP
  den.aspects.networking.networkd-bridge = {
    settings = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "br0";
        description = "Name of the bridge device";
      };
      macAddress = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "MAC address of the bridge (usually the physical NIC's, to keep the DHCP lease)";
      };
    };

    nixos =
      { config, host, ... }:
      let
        cfg = host.settings.networking.networkd-bridge;
      in
      {
        # Force disable DHCP option from facter.
        # The DHCP will be handled by the bridge.
        hardware.facter.detected.dhcp.enable = lib.mkForce false;
        networking.useDHCP = lib.mkForce false;

        systemd.network = {
          enable = true;

          # Define the bridge network device
          netdevs."10-${cfg.name}".netdevConfig = {
            Name = cfg.name;
            Kind = "bridge";
            # NOTE: There's no need to define the `links` to set MACAddressPolicy,
            # because NixOS doesn’t have the 99-default.link file,
            # nothing else will override your MAC (no MACAddressPolicy=persistent).
          }
          // lib.optionalAttrs (cfg.macAddress != null) { MACAddress = cfg.macAddress; };

          networks = {
            # Configure the bridge network
            "20-${cfg.name}" = {
              matchConfig.Name = cfg.name;
              networkConfig = {
                DHCP = "yes";
                UseDomains = "yes";
              };
              linkConfig.RequiredForOnline = "routable";
            };
          }
          # Configure member interfaces of the bridge (detected by facter)
          // lib.genAttrs' config.hardware.facter.detected.dhcp.interfaces (name: {
            name = "30-${cfg.name}-${name}";
            value = {
              matchConfig.Name = name;
              networkConfig.Bridge = cfg.name;
              linkConfig.RequiredForOnline = "enslaved";
            };
          });
        };
      };
  };
}
