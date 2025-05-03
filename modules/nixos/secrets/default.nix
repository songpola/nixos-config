{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
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
  inherit (lib) mkIf mkEnableOption mkMerge;
  inherit (lib.${namespace}) mkHomeConfig;
  this = builtins.baseNameOf ./.;
  cfg = config.${namespace}.${this};
in {
  options.${namespace}.${this} = {
    enable = mkEnableOption "secrets module";
    enableSops = mkEnableOption "SOPS (sops-nix)";
    enableOpnix = mkEnableOption "OPNix (1Password Secrets for NixOS)";
  };
  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.enableSops ({
      sops = {
        defaultSopsFile = ./sops-nix.yaml;
        # For deployment target,
        # this will automatically import SSH keys as age keys.
        age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      };
    }))
    (mkIf cfg.enableOpnix ({
        # Need to be enabled for the Home Manager module to work
        services.onepassword-secrets = {
          enable = true;
          users = [namespace];
          configFile = pkgs.writeText "opnix-config.json" (builtins.toJSON {
            secrets = []; # no system secrets
          });
        };
      }
      // mkHomeConfig {
        programs.onepassword-secrets = mkIf cfg.enableOpnix {
          enable = true;
          secrets = [
            {
              # For client to edit sops secrets,
              # this will get age keys from 1Password.
              path = ".config/sops/age/keys.txt";
              reference = "op://nixos-config/sops-nix-age-key/credential";
            }
          ];
        };
      }))
  ]);
}
