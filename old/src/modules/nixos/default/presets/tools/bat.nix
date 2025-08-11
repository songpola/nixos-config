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
lib.${namespace}.mkPresetModule config [ "tools" "bat" ] {
  systemConfig = [
    # bat - a cat(1) clone with wings
    # https://github.com/sharkdp/bat
    {
      programs.bat = {
        enable = true;
        # NOTE: Need to use Home Manager options
        # to avoid shells integration.
        # extraPackages = with pkgs.bat-extras; [ batman ];
      };
    }
  ];
  homeConfig = [
    {
      programs.bat = {
        enable = true;
        extraPackages = with pkgs.bat-extras; [ batman ];
      };
    }
  ];
  extraConfig = [
    # Use ov as the pager for bat if the preset is enabled
    (mkIfPresetEnabled config
      [
        "tools"
        "ov"
      ]
      {
        systemConfig = [
          {
            # -F, --quit-if-one-screen: Quit if one screen
            # -H3, --header-lines=3: Display 3 fixed lines as header
            # -X, --exit-write: Output on exit
            #
            # NOTE: Delta pager *might* use this environment variable too
            #       if DELTA_PAGER is not set.
            environment.sessionVariables = {
              BAT_PAGER = "ov -F -H3 -X";
            };
          }
          {
            # For batman command
            environment.sessionVariables = {
              MANPAGER = "ov --section-delimiter '^[^\\s]'";
            };

            # Auto generate the immutable cache for man apropos
            documentation.man.generateCaches = true;
          }
        ];
        homeConfig = [
          {
            programs.bat.config = {
              # Ensure that bat does not wrap lines (--wrap=never).
              # If bat wraps lines, it cannot be unwrapped later.
              # It is recommended to use ov for better operation.
              wrap = "never";
            };
          }
        ];
      }
    )
  ];
}
