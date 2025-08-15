{
  delib,
  const,
  moduleSystem,
  homeManagerUser,
  config,
  ...
}:
delib.module {
  name = "home";

  myconfig.always.args.shared.homeconfig =
    if moduleSystem == "home" then config else config.home-manager.users.${homeManagerUser};

  home.always = {
    home = {
      username = homeManagerUser;
      homeDirectory = const.homeDirPath;
    };

    # Enable management of XDG base directories
    # Also add XDG_* env vars
    xdg.enable = true;
  };
}
