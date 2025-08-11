{ lib, pkgs, ... }:
{
  services.tailscale.extraSetFlags = [
    "--advertise-routes=10.0.0.0/16"
    "--advertise-exit-node"
  ];

  # Enable UDP GRO forwarding on the public interface (when routing features are enabled)
  # See: https://tailscale.com/kb/1320/performance-best-practices#linux-optimizations-for-subnet-routers-and-exit-nodes
  # Credit: https://github.com/NixOS/nixpkgs/issues/411980#issuecomment-3129215477
  systemd.services =
    let
      publicInterface = "br0"; # From ./network.nix
      cmd = "${lib.getExe pkgs.ethtool} -K ${publicInterface} rx-udp-gro-forwarding on rx-gro-list off";
    in
    {
      tailscale-udp-gro-forwarding = {
        description = "Enable UDP GRO forwarding for Tailscale";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = cmd;
        };
      };
    };
}
