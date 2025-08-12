{
  delib,
  username,
  const,
  ...
}:
delib.module {
  name = "home";

  home.always = {
    home = {
      username = username;
      homeDirectory = const.homeDirPath;
    };

    # Enable management of XDG base directories
    # Also add XDG_* env vars
    xdg.enable = true;
  };
}
