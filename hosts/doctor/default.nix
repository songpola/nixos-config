{ delib, ... }:
delib.host rec {
  name = "doctor";

  type = "wsl";
  features = [
    "stdenv"
  ];

  system = "x86_64-linux";

  nixos.system.stateVersion = "25.05";
  home.home.stateVersion = "25.05";
}
