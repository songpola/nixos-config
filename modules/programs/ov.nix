{
  den.aspects.programs.ov = {
    # These used to default to the enable state of the tool they integrate
    # with; delta, bat, batman and jujutsu are all in the default set, so they
    # were all on. Drop one here if a host ever stops using that tool.
    # includes = [
    #   my.programs.ov.delta
    #   my.programs.ov.bat
    #   my.programs.ov.batman
    #   my.programs.ov.jujutsu
    # ];

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.ov ];
      };

    homeManager.xdg.configFile."ov/config.yaml".source = ./ov-config.yaml;

    _.default-pager = {
      nixos.environment.variables.PAGER = "ov";
    };

    _.default-pager-for-systemd = {
      nixos.environment.variables.SYSTEMD_PAGERSECURE = "false";
    };

    # # -F, --quit-if-one-screen: Quit if one screen
    # # NOTE: No need to use `--raw` option; ov can handle the escape sequences
    # delta.nixos.environment.sessionVariables.DELTA_PAGER = "ov -F";

    # bat = {
    #   # -F, --quit-if-one-screen: Quit if one screen
    #   # -H3, --header-lines=3: Display 3 fixed lines as header
    #   # -X, --exit-write: Output on exit
    #   #
    #   # NOTE: Delta pager *might* use this environment variable too
    #   #       if `DELTA_PAGER` env var is not set.
    #   nixos.environment.sessionVariables.BAT_PAGER = "ov -F -H3 -X";

    #   # Ensure that bat does not wrap lines (--wrap=never).
    #   # If bat wraps lines, it cannot be unwrapped later.
    #   # It is recommended to use ov for better operation.
    #   homeManager.programs.bat.config.wrap = "never";
    # };

    # # For the `batman` command
    # batman.nixos.environment.sessionVariables.MANPAGER = "ov --section-delimiter '^[^\\s]'";

    # # Since v0.36.0, jj now ignores $PAGER set in the environment
    # jujutsu.homeManager =
    #   { lib, ... }:
    #   {
    #     programs.jujutsu.settings.ui.pager = lib.mkDefault "ov";
    #   };
  };
}
