{ delib, host, ... }:
delib.module {
  name = "networking";

  nixos.always.networking = {
    hostName = host.name;

    # Use nftables instead of iptables
    nftables.enable = true;
  };
}
