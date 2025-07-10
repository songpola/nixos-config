{ lib, config, ... }:
let
  inherit (lib) mkMerge mkIf;
  inherit (lib.songpola) useCore;
in
mkMerge [
  (mkIf (config |> useCore "wsl") {
    wsl.enable = true;
  })
]
