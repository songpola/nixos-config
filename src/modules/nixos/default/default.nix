{ lib, namespace, ... }:
let
  inherit (lib) mkOption types;
  inherit (lib.snowfall.fs) get-non-default-nix-files-recursive;
in
{
  imports = get-non-default-nix-files-recursive ./.;

  options = {
    ${namespace} = {
      base = mkOption {
        type = types.str;
      };
      presets = mkOption {
        type = types.listOf types.str;
      };
    };
  };
}
