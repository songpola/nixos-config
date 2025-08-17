{ delib, ... }:
delib.module {
  name = "nh.clean";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = delib.ifParentEnabled "nh" {
    # Auto clean (all) (default: weekly)
    # NOTE: No need to use the options from Home Manager,
    # because all the profiles (system and user) will be cleaned by this options.
    programs.nh.clean.enable = true;
  };
}
