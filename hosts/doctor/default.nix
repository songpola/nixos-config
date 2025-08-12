{ delib, ... }:
delib.host {
  name = "doctor";

  type = "wsl";
  features = [
    "stdenv"
    "presets.devenv.nix"
  ];

  system = "x86_64-linux";

  nixos.system.stateVersion = "25.05";
  home.home.stateVersion = "25.05";

  nixos = {
    # FIXME: fastfetch patch doesn't work
    nixowos = {
      # Make this system *cute* ( •̀ ω •́ )✧
      enable = true;

      # NOTE: Starship prompt don't know NixOwOS and will show default linux icon
      os-release.enable = false;
    };
  };
}
