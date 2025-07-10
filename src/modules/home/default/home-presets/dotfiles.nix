{
  lib,
  config,
  ...
}:
lib.songpola.mkHomePresetModule config [ "dotfiles" ] {
  home.file = {
    ".nirc".source = ./config/.nirc;

    ".czrc".source = ./config/.czrc;
  };
}
