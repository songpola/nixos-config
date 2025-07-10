{ lib, ... }:
let
  inherit (lib.snowfall.fs) get-non-default-nix-files-recursive;
in
{
  imports = get-non-default-nix-files-recursive ./.;
}
