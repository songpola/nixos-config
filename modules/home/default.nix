{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  # inputs,
  # Additional metadata is provided by Snowfall Lib.
  # namespace, # The namespace used for your flake, defaulting to "internal" if not set.
  # system, # The system architecture for this host (eg. `x86_64-linux`).
  # target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  # format, # A normalized name for the system target (eg. `iso`).
  # virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  # systems, # An attribute map of your defined hosts.
  # All other arguments come from the module system.
  # config,
  ...
}: let
  inherit (lib.songpola) enableOptions;
in {
  # Common packages, installed on all hosts
  home.packages = with pkgs; [
    wget # Required by VS Code Remote Extension
    nil
    alejandra
    httpie
    ov
  ];

  programs =
    lib.recursiveUpdate
    (
      enableOptions [
        "home-manager"
        "git"
        "micro"
        "nushell"
        "fish"
        "starship"
        "carapace"
        "eza"
        "yazi"
        "atuin"
        "bat"
        "ripgrep"
        "zoxide"
        "thefuck"
        "fzf"
        "tealdeer"
      ]
    )
    {
      git = {
        userEmail = "1527535+songpola@users.noreply.github.com";
        userName = "Songpol Anannetikul";
        extraConfig = {
          init.defaultBranch = "main";
        };
        delta.enable = true;
      };
      eza = {
        git = true;
        icons = true;
        enableNushellIntegration = true;
      };
      yazi.enableNushellIntegration = true;
      atuin.enableNushellIntegration = false; # https://github.com/nushell/nushell/issues/10414
    };
}
