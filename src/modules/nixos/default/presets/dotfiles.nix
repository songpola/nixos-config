{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkHomeConfigModule getConfigPath;

  getDotfilesPath = path: getConfigPath "/dotfiles/${path}";
in
lib.${namespace}.mkPresetModule config [ "dotfiles" ] (mkHomeConfigModule {
  home.file = {
    ".nirc".source = getDotfilesPath ".nirc";
    ".czrc".source = getDotfilesPath ".czrc";
  };
})
