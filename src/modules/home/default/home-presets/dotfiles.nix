{
  lib,
  config,
  ...
}:
let
  inherit (lib.songpola) getConfigPath;

  getDotfilesPath = path: getConfigPath "/dotfiles/${path}";
in
lib.songpola.mkHomePresetModule config [ "dotfiles" ] {
  home.file = {
    ".nirc".source = getDotfilesPath ".nirc";
    ".czrc".source = getDotfilesPath ".czrc";
  };
}
