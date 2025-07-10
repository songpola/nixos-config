{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkMerge mkIf;
  inherit (lib.${namespace}) usePreset;
in
mkMerge [
  # My standard environment
  # NOTE: This preset also includes `env.mini` preset.
  #       See `./mini.nix` for more details.
  (mkIf (config |> usePreset "env.std") {
  })
]
