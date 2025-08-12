{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "delta.integrations.jujutsu";

  options = { myconfig, ... }@args: delib.singleEnableOption myconfig.jujutsu.enable args;

  home.ifEnabled = {
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
  };
}
