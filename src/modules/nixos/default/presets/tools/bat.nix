{
  lib,
  config,
  namespace,
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
      programs.bat.enable = true;
    }
  ];
  homeConfig = [
    {
      programs.bat.enable = true;
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
            environment.variables = {
              # -F, --quit-if-one-screen: Quit if one screen
              # -H3, --header-lines=3: Display 3 fixed lines as header
              # -X, --exit-write: Output on exit
              #
              # NOTE: Delta pager *might* use this environment variable too
              #       if DELTA_PAGER is not set.
              BAT_PAGER = "ov -F -H3 -X";
            };
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
