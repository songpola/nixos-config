{
  lib,
  config,
  namespace,
  ...
}:
lib.${namespace}.mkPresetModule config [ "stdenv" "full" ] {
  systemConfig = [
    {
      ${namespace}.presets = {
        # Extends the minimal standard environment preset
        stdenv.mini = true;

        shells = true;

        tools = {
          direnv = true;
          delta = true;
          just = true;

          ssh = true;
          isd = true;

          httpie = true;
        };

        devenv = {
          nix = true;
        };
      };

      # NOTE: Not sure why do I need this.
      # Enable polkit for managing system permissions
      # security.polkit.enable = true;
    }
  ];
  homeConfig = [
    {
      # Enable management of XDG base directories
      xdg.enable = true;
    }
  ];
}
