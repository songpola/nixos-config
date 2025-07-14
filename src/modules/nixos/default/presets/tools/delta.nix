{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib.${namespace}) mkIfPresetEnabled;
in
lib.${namespace}.mkPresetModule config [ "tools" "delta" ] {
  systemConfig = [
    {
      # delta - a syntax-highlighting pager for git, diff, grep, and blame output
      # https://github.com/dandavison/delta
      environment.systemPackages = [ pkgs.delta ];
    }
  ];
  homeConfig = [
    {
      # Use delta as the default pager for git
      # TODO: https://noborus.github.io/ov/delta/index.html
      programs.git.delta.enable = true;

      # Use delta as the default pager for jujutsu
      programs.jujutsu = {
        settings = {
          ui = {
            pager = "${pkgs.delta}/bin/delta";
            diff-formatter = ":git";
          };
          # merge-tools.delta = {
          #   diff-expected-exit-codes = [
          #     0
          #     1
          #   ];
          # };
        };
      };
    }
  ];
  extraConfig = [
    # Use ov as the pager for delta if the preset is enabled
    (mkIfPresetEnabled config
      [
        "tools"
        "ov"
      ]
      {
        systemConfig = [
          {
            environment.variables = {
              # -F, --quit-if-one-screen: Quit if one screen
              # NOTE: No need to use `--raw` option; ov can handle the escape sequences
              DELTA_PAGER = "ov -F";
            };
          }
        ];
      }
    )
  ];
}
