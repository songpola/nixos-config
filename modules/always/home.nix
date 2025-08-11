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
  };
}
