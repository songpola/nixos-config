{
  # # https://snowfall.org/guides/lib/modules/
  # # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # # as well as the libraries available from your flake's inputs.
  lib,
  # # An instance of `pkgs` with your overlays and packages applied is also available.
  # pkgs,
  # # You also have access to your flake's inputs.
  # inputs,
  # # Additional metadata is provided by Snowfall Lib.
  # namespace, # The namespace used for your flake, defaulting to "internal" if not set.
  # system, # The system architecture for this host (eg. `x86_64-linux`).
  # target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  # format, # A normalized name for the system target (eg. `iso`).
  # virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  # systems, # An attribute map of your defined hosts.
  # # All other arguments come from the module system.
  # config,
  ...
}: let
  extraConfigBefore = lib.readFile ./config.nu;
  extraConfigAfter = lib.concatLines (
    map (f: lib.readFile f) [
      ./pixi.nu
      ./external_completer.nu
    ]
  );
in {
  programs.nushell = {
    enable = true;
    envFile.source = ./default_env.nu;
    configFile.source = ./default_config.nu;
    extraConfig = lib.mkMerge [
      (lib.mkBefore extraConfigBefore)
      (lib.mkAfter extraConfigAfter)
    ];
    environmentVariables = {
      VISUAL = ["code" "--wait"];
      EDITOR = "micro";
      PAGER = "ov";
      BAT_PAGER = "ov -F -H3";
      MANPAGER = "ov --section-delimiter '^[^\\s]' --section-header";
    };
  };
}
