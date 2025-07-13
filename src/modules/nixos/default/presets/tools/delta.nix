{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkMerge mkIf;
  inherit (lib.${namespace}) mkHomeConfigModule hasPresetEnabled;
in
lib.${namespace}.mkPresetModule config [ "tools" "delta" ] (mkMerge [
  {
    # delta - a syntax-highlighting pager for git, diff, grep, and blame output
    # https://github.com/dandavison/delta
    environment.systemPackages = [ pkgs.delta ];
  }
  (mkHomeConfigModule {
    # Use delta as the default pager for git
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
  })
  # Use ov as the pager for delta if the preset is enabled
  (mkIf
    (
      config
      |> hasPresetEnabled [
        "tools"
        "ov"
      ]
    )
    {
      environment.variables = {
        # -F, --quit-if-one-screen: Quit if one screen
        # -X, --exit-write: Output on exit
        # NOTE: No need to use `--raw` option; ov can handle the escape sequences
        DELTA_PAGER = "ov -F -X";
      };
    }
  )
])
