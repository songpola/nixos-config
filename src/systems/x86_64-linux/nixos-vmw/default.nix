{
  # # https://snowfall.org/guides/lib/systems/
  # # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # # as well as the libraries available from your flake's inputs.
  lib,
  # # An instance of `pkgs` with your overlays and packages applied is also available.
  # # FIXME: `error: attribute 'pkgs' missing`
  # # When: comment out this line (like now) and try to use `pkgs` in config.
  # # Example: `{ pkgs, ... }: { ... = with pkgs; ... }`
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
} @ inputs:
lib.${namespace}.mkHaumeaModule inputs ./.
