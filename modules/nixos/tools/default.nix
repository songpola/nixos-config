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
  inherit (lib) mkEnableOption mkIf optionals;
  inherit (lib.${namespace}) mkDefaultEnableOption;
  this = builtins.baseNameOf ./.;
  cfg = config.${namespace}.${this};
in {
  options.${namespace}.${this} = {
    enable = mkEnableOption "tools module";
    development = mkDefaultEnableOption "development tools";
    sysadmin = mkDefaultEnableOption "sysadmin tools";
    utils = mkDefaultEnableOption "utility tools";
  };
  config = mkIf cfg.enable {
    # python: pixi
    ${namespace}.pixi.enable = mkIf cfg.development true;

    # Home Manager configs
    snowfallorg.users.${namespace}.home.config = {
      home.packages = with pkgs;
        (optionals cfg.development [
          just # task runner
          watchexec # file watcher
          caddy # use as formatter
          # dev environment
          devbox
          coder
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
        ])
        ++ (optionals cfg.sysadmin [
          btop # system monitor
          duf # `df` replacement
          dust # `du` replacement
          rustscan # port scanner
          lsof # list open files
          isd # interactive systemd
        ])
        ++ (optionals cfg.utils [
          doggo # DNS client
          httpie # HTTP client
          wget # file downloader
          croc # file transfer
          jq # JSON processor
          ouch # archive extractor
          sops # secrets management
          xkcdpass # password generator
        ]);
    };
  };
}
