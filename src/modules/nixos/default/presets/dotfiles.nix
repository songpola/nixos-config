{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) getConfigPath;

  getDotfilesPath = path: getConfigPath "/dotfiles/${path}";
in
lib.${namespace}.mkPresetModule config [ "dotfiles" ] {
  homeConfig = [
    {
      home.file = {
        ".nirc".source = getDotfilesPath ".nirc";
        ".czrc".source = getDotfilesPath ".czrc";
      };
    }
  ];
}
