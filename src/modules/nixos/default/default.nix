{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkOption types;
  inherit (lib.snowfall.fs) get-non-default-nix-files-recursive;
in
{
  imports = get-non-default-nix-files-recursive ./.;

  options = {
    ${namespace} = {
      stateVersions = {
        system = mkOption {
          type = types.str;
        };
        home = mkOption {
          type = types.str;
        };
      };

      # Config for each base system option will be defined in their respective modules
      base = mkOption {
        type = types.str;
      };

      # Options for each preset will be declared in their respective modules
      # presets = ...

      # Shortcuts for setting home presets
      homePresets = mkOption {
        type = types.attrsOf types.bool;
        default = { };
      };
    };
  };

  config = {
    system.stateVersion = config.${namespace}.stateVersions.system;

    snowfallorg.users.${namespace}.home.config = {
      home.stateVersion = config.${namespace}.stateVersions.home;

      # Delegate from system config to home config
      ${namespace}.homePresets = config.${namespace}.homePresets;
    };
  };
}
