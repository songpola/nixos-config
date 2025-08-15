{
  delib,
  ...
}:
delib.module {
  name = "dotfiles";

  options = delib.singleEnableOption false;

  home.ifEnabled.home.file = {
    ".nirc".source = ./.nirc;
    ".czrc".source = ./.czrc;
  };
}
