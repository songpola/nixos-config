{
  delib,
  ...
}:
delib.module {
  name = "bat.integrations.ov";

  options = { myconfig, ... }@args: delib.singleEnableOption myconfig.ov.enable args;

  nixos.ifEnabled = {
    # -F, --quit-if-one-screen: Quit if one screen
    # -H3, --header-lines=3: Display 3 fixed lines as header
    # -X, --exit-write: Output on exit
    #
    # NOTE: Delta pager *might* use this environment variable too
    #       if DELTA_PAGER is not set.
    environment.sessionVariables = {
      BAT_PAGER = "ov -F -H3 -X";
    };
  };

  home.ifEnabled = {
    programs.bat.config = {
      # Ensure that bat does not wrap lines (--wrap=never).
      # If bat wraps lines, it cannot be unwrapped later.
      # It is recommended to use ov for better operation.
      wrap = "never";
    };
  };
}
