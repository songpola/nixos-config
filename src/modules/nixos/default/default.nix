{ lib, ... }:
let
  inherit (lib) mkOption types;
  inherit (lib.snowfall.fs) get-non-default-nix-files-recursive;
in
{
  imports = get-non-default-nix-files-recursive ./.;

  options = {
    core = mkOption {
      type = types.str;
    };
    api = mkOption {
      type = types.listOf types.str;
    };
  };
}
