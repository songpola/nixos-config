{ lib, config, ... }:
let
  inherit (lib) mkMerge mkIf;
  inherit (lib.songpola) useApi useCore;
in
mkMerge [
  (mkIf (config |> useApi "user") (mkMerge [
    (mkIf (config |> useCore "wsl") {
      wsl.defaultUser = "songpola";
    })
  ]))
]
