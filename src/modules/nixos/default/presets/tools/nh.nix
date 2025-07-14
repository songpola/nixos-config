{
  lib,
  config,
  namespace,
  ...
}:
lib.${namespace}.mkPresetModule2 config [ "tools" "nh" ] {
  systemConfig = [
    {
      # nh - Yet another Nix CLI helper
      # https://github.com/nix-community/nh
      #
      # NOTE: No need to use the options from Home Manager,
      # because all the profiles (system and user) will be cleaned by this options.
      programs.nh = {
        enable = true;
        clean.enable = true; # auto clean (all) (default: weekly)
      };
    }
  ];
}
