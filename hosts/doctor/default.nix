{ delib, pkgs, ... }:
delib.host {
  name = "doctor";

  type = "wsl";
  system = "x86_64-linux";
  features = [ "stdenv" ];

  nixos.system.stateVersion = "25.05";
  home.home.stateVersion = "25.05";

  myconfig = {
    nixowos.enable = true;

    podman.enable = true;

    devenv = {
      nix.enable = true;
      node.enable = true;
      nickel.enable = true;
    };
  };

  nixos = {
    wsl.startMenuLaunchers = true;

    programs.virt-manager.enable = true;

    environment.systemPackages = [ pkgs.devenv ];
  };
}
