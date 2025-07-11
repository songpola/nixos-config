{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
lib.${namespace}.mkPresetModule config [ "stdenv" ] {
  # Nix settings
  nix.settings.experimental-features = [
    "flakes"
    "nix-command"
    "pipe-operators"
  ];

  # Set timezone to Bangkok
  time.timeZone = "Asia/Bangkok";

  # Git
  programs.git.enable = true;

  # Use micro as default (and fallback) text editor
  environment = {
    systemPackages = [ pkgs.micro ];
    variables = {
      EDITOR = "micro";
    };
  };

  # nh: "Yet another Nix CLI helper."
  # https://github.com/nix-community/nh
  programs.nh = {
    enable = true;
    clean.enable = true; # auto clean (default: weekly)
  };
}
