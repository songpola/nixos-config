{
  den.aspects.programs.nh = {
    nixos.programs.nh.enable = true;

    # Auto clean (all), weekly.
    # NOTE: No need to use the options from Home Manager, because all the
    # profiles (both system and user) are cleaned by this option.
    _.auto-clean-weekly = {
      nixos.programs.nh.clean.enable = true;
    };
  };
}
