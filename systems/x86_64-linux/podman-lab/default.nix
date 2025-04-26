{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  # lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  # pkgs,
  # You also have access to your flake's inputs.
  # inputs,
  # Additional metadata is provided by Snowfall Lib.
  namespace, # The namespace used for your flake, defaulting to "internal" if not set.
  # system, # The system architecture for this host (eg. `x86_64-linux`).
  # target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  # format, # A normalized name for the system target (eg. `iso`).
  # virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  # systems, # An attribute map of your defined hosts.
  # All other arguments come from the system system.
  # config,
  host,
  ...
}: let
  inherit (builtins) hashString substring concatStringsSep;

  generateMacAddress = s: let
    hash = hashString "sha256" s;
    c = off: substring off 2 hash;
  in
    concatStringsSep ":" [
      "${substring 0 1 hash}2"
      (c 2)
      (c 4)
      (c 6)
      (c 8)
      (c 10)
    ];
in {
  ${namespace} = {
    stateVersions = {
      system = "24.11";
      home = "24.11";
    };

    bootloader.grubEfi.enable = true;

    profiles = {
      guest = {
        enable = true;
        qemu = true;
      };
    };
  };

  microvm.interfaces = [
    {
      type = "tap";
      id = "vm-${host}";
      mac = generateMacAddress host;
    }
  ];
}
