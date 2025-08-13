{
  delib,
  pkgs,
  ...
}:
delib.module {
  # starship - a cross-shell prompt
  # https://github.com/starship/starship
  name = "starship";

  options = delib.singleEnableOption false;

  # NOTE: Custom starship integration implementation.
  # The NixOS options don't have Nushell integration and
  # the current Nushell integration in Home Manager is too old (since 2022).
  #
  # TODO: Implement custom system-wide integration
  home.ifEnabled = {
    home.packages = [ pkgs.starship ];
  };
}
