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
          ripgrep = true;
          sysadmin = true;
        };

        devenv = {
          nix = true;
        };
      };
    }
    {
      # FIXME: fastfetch patch doesn't work

      # Make this system *cute* OwO
      # NOTE: This is mandatory ( •̀ ω •́ )✧
      nixowos.enable = true;

      # NOTE: Starship prompt don't know NixOwOS and will show default linux icon
      nixowos.os-release.enable = false;
    }
  ];
  homeConfig = [
    {
      # Enable management of XDG base directories
      xdg.enable = true;
    }
  ];
}
