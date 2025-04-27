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
  inherit (lib) mkEnableOption mkIf optionals mkMerge;
  inherit (lib.${namespace}) mkDefaultEnableOption mkHomeConfig;
  this = builtins.baseNameOf ./.;
  cfg = config.${namespace}.${this};
in {
  options.${namespace}.${this} = {
    enable = mkDefaultEnableOption "tools module";
    utils = mkDefaultEnableOption "utility tools";
    sysadmin = mkDefaultEnableOption "sysadmin tools";
    development = mkEnableOption "development tools";
  };
  config = let
    nvidiaEnable = config.${namespace}.hardware.nvidia.enable;
  in
    mkIf cfg.enable (
      mkMerge [
        (mkIf cfg.utils (mkHomeConfig {
          programs = {
            jq.enable = true;
          };
          home.packages = with pkgs; [
            doggo # DNS client
            httpie # HTTP client
            wget # file downloader
            croc # file transfer
            ouch # archive extractor
            sops # secrets management
            xkcdpass # password generator
            aria2 # download utility
          ];
        }))
        (mkIf cfg.sysadmin (mkHomeConfig {
          programs = {
            btop = {
              enable = true;
              # Enable CUDA support for btop if NVIDIA GPU is enabled
              package = mkIf nvidiaEnable pkgs.btopCuda;
            };
          };
          home.packages = with pkgs;
            [
              duf # `df` replacement
              dust # `du` replacement
              rustscan # port scanner
              lsof # list open files
              isd # interactive systemd
              pciutils # PCI info
              lshw # hardware info
            ]
            ++ (optionals nvidiaEnable [
              nvitop # GPU monitoring
            ]);
        }))
        (mkIf cfg.development (
          {
            # pixi (python)
            ${namespace}.pixi.enable = true;
          }
          // mkHomeConfig {
            home.packages = with pkgs; (optionals cfg.development [
              just # task runner
              watchexec # file watcher

              # dev environment
              devbox

              # nix
              nil
              nixd
              alejandra
              deploy-rs
              nix-diff
              nvd

              # node
              nodejs
              pnpm
            ]);
          }
        ))
      ]
    );
}
