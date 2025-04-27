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
  inherit (lib) mkEnableOption mkIf;
  this = builtins.baseNameOf ./.;
  cfg = config.${namespace}.${this};
in {
  options.${namespace}.${this} = {
    enable = mkEnableOption "distributed builds (use PRTS as build machine)";
  };
  config = mkIf cfg.enable {
    nix = {
      distributedBuilds = true;
      settings = {
        builders-use-substitutes = true;
      };
      buildMachines = [
        {
          hostName = "prts.tail7623c.ts.net";
          sshUser = namespace;
          system = "-"; # omitted, will defaults to the local platform type.
          supportedFeatures = [
            "nixos-test"
            "benchmark"
            "big-parallel"
            "kvm"
          ];
          protocol = "ssh-ng";
          maxJobs = 12; # 12 cpu cores
          speedFactor = 2;
          # Get the publicHostKey from: base64 -w0 /etc/ssh/ssh_host_ed25519_key.pub
          publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUJEMXIvanJrSmJDWEs3cDZSTmQ0K2Z5Q2N4WUNsN3RkUHdJR2FXTGhqenEgcm9vdEBwcnRzCg==";
        }
      ];
    };
  };
}
