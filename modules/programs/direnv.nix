{
  # The NixOS and Home Manager options won't conflict each other,
  # see ./direnv.md for more details.
  den.aspects.programs.direnv = {
    nixos.programs.direnv = {
      # nix-direnv is enabled by default
      enable = true;
      settings.global = {
        warn_timeout = 0;
        hide_env_diff = true;
      };
    };

    homeManager.programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
