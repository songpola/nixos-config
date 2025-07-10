{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkMerge mkIf;
  inherit (lib.${namespace}) useAnyPresets;
in
mkMerge [
  # My minimal environment
  # NOTE: This preset can be activated by `env.mini` or `env.std`.
  (mkIf
    (
      config
      |> useAnyPresets [
        "env.mini"
        "env.std"
      ]
    )
    {
      # Nix settings
      nix.settings.experimental-features = [
        "flakes"
        "nix-command"
        "pipe-operators"
      ];

      # Essential packages

      # Git
      programs.git.enable = true;

      # Use micro as default (and fallback) text editor
      environment = {
        systemPackages = [ pkgs.micro ];
        variables = {
          EDITOR = "micro";
        };
      };

      # nh: "Yet another Nix CLI helper."
      # https://github.com/nix-community/nh
      programs.nh = {
        enable = true;
        clean.enable = true; # auto clean (default: weekly)
      };
    }
  )
]
