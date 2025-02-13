{
  # # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # # as well as the libraries available from your flake's inputs.
  lib,
  # # An instance of `pkgs` with your overlays and packages applied is also available.
  # pkgs,
  # # You also have access to your flake's inputs.
  # inputs,
  # # Additional metadata is provided by Snowfall Lib.
  namespace, # The namespace used for your flake, defaulting to "internal" if not set.
  # system, # The system architecture for this host (eg. `x86_64-linux`).
  # target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  # format, # A normalized name for the system target (eg. `iso`).
  # virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  # systems, # An attribute map of your defined hosts.
  # # All other arguments come from the system system.
  # config,
  ...
}:  let
  inherit (lib.${namespace}) prts;
in {
  nix = {
    settings = {
      substituters = [
        "http://${prts.fqdn}:5000/"
        # "https://nix-community.cachix.org"
        # "https://cache.nixos.org/" # default
      ];
      trusted-public-keys = [
        prts.binaryCachePublicKey
      ];
    };
    # You can see the resulting builder-strings of this NixOS-configuration with "cat /etc/nix/machines".
    # These builder-strings are used by the Nix terminal tool, e.g.
    # when calling "nix build ...".
    buildMachines = [
      {
        # Will be used to call "ssh builder" to connect to the builder machine.
        # The details of the connection (user, port, url etc.)
        # are taken from your "~/.ssh/config" file.
        hostName = "prts";
        # CPU architecture of the builder, and the operating system it runs.
        # Replace the line by the architecture of your builder, e.g.
        # - Normal Intel/AMD CPUs use "x86_64-linux"
        # - Raspberry Pi 4 and 5 use  "aarch64-linux"
        # - M1, M2, M3 ARM Macs use   "aarch64-darwin"
        # - Newer RISCV computers use "riscv64-linux"
        # See https://github.com/NixOS/nixpkgs/blob/nixos-unstable/lib/systems/flake-systems.nix
        # If your builder supports multiple architectures
        # (e.g. search for "binfmt" for emulation),
        # you can list them all, e.g. replace with
        # systems = ["x86_64-linux" "aarch64-linux" "riscv64-linux"];
        system = "x86_64-linux";
        # Nix custom ssh-variant that avoids lots of "trusted-users" settings pain
        protocol = "ssh-ng";
        # default is 1 but may keep the builder idle in between builds
        maxJobs = 3;
        # how fast is the builder compared to your local machine
        speedFactor = 2;
        supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
        mandatoryFeatures = [];
      }
    ];
    # required, otherwise remote buildMachines above aren't used
    distributedBuilds = true;
    # optional, useful when the builder has a faster internet connection than yours
    settings = {
      builders-use-substitutes = true;
    };
  };
}
