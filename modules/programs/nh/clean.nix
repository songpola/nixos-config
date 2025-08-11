{
  delib,
  host,
  ...
}:
delib.module {
  name = "nh.clean";

  # Enabled by default on WSL
  options = delib.singleEnableOption host.isWsl;

  nixos.ifEnabled = {
    # Auto clean (all) (default: weekly)
    # NOTE: No need to use the options from Home Manager,
    # because all the profiles (system and user) will be cleaned by this options.
    programs.nh.clean.enable = true;
  };
}
