{ delib, ... }:
delib.host {
  name = "prts";

  # Use nftables instead of iptables
  nixos.networking.nftables.enable = true;
}
