{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  # inputs,
  # Additional metadata is provided by Snowfall Lib.
  # system, # The system architecture for this host (eg. `x86_64-linux`).
  # target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  # format, # A normalized name for the system target (eg. `iso`).
  # virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  # systems, # An attribute map of your defined hosts.
  # All other arguments come from the system system.
  # config,
  ...
}: {
  wsl = {
    enable = true;
    defaultUser = "songpola";
    startMenuLaunchers = true;

    # Docker Desktop Integration workarounds
    # https://github.com/nix-community/NixOS-WSL/issues/235
    docker-desktop.enable = false;
    extraBin = with pkgs; [
      {src = "${uutils-coreutils-noprefix}/bin/mkdir";}
      {src = "${uutils-coreutils-noprefix}/bin/cat";}
      {src = "${uutils-coreutils-noprefix}/bin/whoami";}
      {src = "${uutils-coreutils-noprefix}/bin/ls";}
      {src = "${busybox}/bin/addgroup";}
      {src = "${su}/bin/groupadd";}
      {src = "${su}/bin/usermod";}
    ];
  };

  networking.hostName = lib.snowfall.system.get-inferred-system-name ./.;

  # environment.systemPackages = with pkgs; [
  #   gnome-icon-theme
  #   gnome.adwaita-icon-theme
  # ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  programs.nh.flake = with config; users.users.${wsl.defaultUser}.home + "/nixos-config";
}
