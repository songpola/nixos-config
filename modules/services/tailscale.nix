{ lib, ... }:
{
  den.aspects.services.tailscale = {
    settings = {
      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Open the Tailscale UDP port in the firewall to improve connectivity";
      };
      operator = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "User allowed to operate tailscaled without sudo (tailscale accepts only one)";
      };
      ssh = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Run Tailscale SSH server";
      };
      advertiseRoutes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Subnet routes to advertise, e.g. 10.0.0.0/16";
      };
      advertiseExitNode = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Advertise this host as an exit node";
      };
      useExitNodes = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Use exit nodes / subnet routes advertised by other nodes (loosens reverse path filtering)";
      };
      optimizeUdpInterface = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Physical interface to tune for UDP throughput (UDP GRO forwarding, offloads); for subnet routers and exit nodes";
      };
    };

    nixos =
      {
        config,
        pkgs,
        host,
        ...
      }:
      let
        cfg = host.settings.services.tailscale;
        isServer = cfg.advertiseRoutes != [ ] || cfg.advertiseExitNode;
        isNetworkdEnabled = config.systemd.network.enable;
      in
      lib.mkMerge [
        {
          services.tailscale = {
            enable = true;
            package = pkgs.unstable.tailscale;
            openFirewall = cfg.openFirewall;

            useRoutingFeatures =
              if isServer && cfg.useExitNodes then
                "both"
              else if isServer then
                "server"
              else if cfg.useExitNodes then
                "client"
              else
                "none";

            extraSetFlags =
              lib.optional (cfg.operator != null) "--operator=${cfg.operator}"

              ++ lib.optional cfg.ssh "--ssh"

              ++ lib.optional (
                cfg.advertiseRoutes != [ ]
              ) "--advertise-routes=${lib.concatStringsSep "," cfg.advertiseRoutes}"

              ++ lib.optional cfg.advertiseExitNode "--advertise-exit-node";
          };
        }

        # Without networkd, useRoutingFeatures alone is enough.
        # Otherwise, networkd would reset the forwarding that useRoutingFeatures sets via sysctl.
        (lib.mkIf (isServer && isNetworkdEnabled) {
          systemd.network.config.networkConfig = {
            IPv4Forwarding = "yes";
            IPv6Forwarding = "yes";
          };
        })

        # https://tailscale.com/kb/1320/performance-best-practices#linux-optimizations-for-subnet-routers-and-exit-nodes
        # https://tailscale.com/blog/quic-udp-throughput
        (lib.mkIf (cfg.optimizeUdpInterface != null) (
          lib.mkMerge [
            {
              warnings =
                lib.optional (!isServer)
                  "services.tailscale.optimizeUdpInterface is ignored: the host neither advertises routes nor is an exit node.";
            }

            # To enable `generic-segmentation-offload`,
            # these dependencies need to be enabled for it to be auto-enabled:
            # sg (scatter-gather), tso (tcp-segmentation-offload)
            (lib.mkIf (isServer && isNetworkdEnabled) {
              systemd.network.links."10-${cfg.optimizeUdpInterface}" = {
                matchConfig.OriginalName = cfg.optimizeUdpInterface;
                linkConfig = {
                  GenericReceiveOffloadUDPForwarding = "yes";
                  GenericReceiveOffloadList = "no";
                  ScatterGather = "yes";
                  TCPSegmentationOffload = "yes";
                };
              };
            })

            # Fallback without networkd: apply the same features with ethtool once the device appears.
            (lib.mkIf (isServer && !isNetworkdEnabled) {
              systemd.services.tailscale-udp-optimize =
                let
                  device = "sys-subsystem-net-devices-${
                    lib.replaceStrings [ "-" ] [ "\\x2d" ] cfg.optimizeUdpInterface
                  }.device";
                in
                {
                  description = "Optimize ${cfg.optimizeUdpInterface} for Tailscale UDP throughput";
                  bindsTo = [ device ];
                  after = [ device ];
                  wantedBy = [ device ];
                  serviceConfig = {
                    Type = "oneshot";
                    ExecStart = "${lib.getExe pkgs.ethtool} -K ${cfg.optimizeUdpInterface} sg on tso on rx-udp-gro-forwarding on rx-gro-list off";
                  };
                };
            })
          ]
        ))
      ];
  };
}
