{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  # pkgs,
  # You also have access to your flake's inputs.
  # inputs,
  # Additional metadata is provided by Snowfall Lib.
  namespace, # The namespace used for your flake, defaulting to "internal" if not set.
  # system, # The system architecture for this host (eg. `x86_64-linux`).
  # target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  # format, # A normalized name for the system target (eg. `iso`).
  # virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  # systems, # An attribute map of your defined hosts.
  # All other arguments come from the module system.
  config,
  ...
}: let
  inherit (lib) mkOption mkIf mkEnableOption mkMerge;
  this = builtins.baseNameOf ./.;
  cfg = config.${namespace}.${this};
in {
  options.${namespace}.${this} = {
    guest = {
      enable = mkEnableOption "VM guest profile";
      vmware = mkEnableOption "VMware-specific guest profile";
      qemu = mkEnableOption "QEMU-specific guest profile";
    };
    wsl.enable = mkEnableOption "profile for WSL";
    server.enable = mkEnableOption "profile for servers";
  };
  config = mkMerge [
    (
      mkIf cfg.guest.enable (mkMerge [
        {
          services.openssh.enable = true;

          users.users.${namespace}.initialHashedPassword = "";
          services.getty.autologinUser = namespace;

          services.xserver.videoDrivers = mkIf cfg.guest.vmware ["vmware"];
          virtualisation.vmware.guest.enable = mkIf cfg.guest.vmware true;
        }
        (mkIf cfg.guest.vmware {
          services.xserver.videoDrivers = ["vmware"];
          virtualisation.vmware.guest.enable = true;
        })
        (mkIf cfg.guest.qemu {
          services.qemuGuest.enable = true;
          services.spice-vdagentd.enable = true;
        })
      ])
    )
    (
      mkIf cfg.wsl.enable {
        wsl = {
          enable = true;
          defaultUser = namespace;
          startMenuLaunchers = true;
        };
      }
    )
    (
      mkIf cfg.server.enable {
        services = {
          openssh.enable = true;

          tailscale = {
            enable = true;
            openFirewall = true;
            useRoutingFeatures = "server";
            extraSetFlags = [
              "--operator=${namespace}"
              "--ssh"
            ];
          };
        };
      }
    )
  ];
}
