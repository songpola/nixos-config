{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkMerge mkIf;
  inherit (lib.${namespace}) useBase;
in
mkMerge [
  (mkIf (config |> useBase "wsl") {
    wsl.enable = true;
    wsl.defaultUser = namespace; # songpola
  })
]
