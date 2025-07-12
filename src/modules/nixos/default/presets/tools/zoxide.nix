{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkMerge;
  inherit (lib.${namespace}) mkHomeConfigModule;
in
lib.${namespace}.mkPresetModule config [ "tools" "zoxide" ] (mkMerge [
  {
    # zoxide - a smarter cd command
    # https://github.com/ajeetdsouza/zoxide
    programs.zoxide.enable = true;

    # zoxide uses fzf for completions / interactive selection
    ${namespace}.presets.tools.fzf = true;
  }
  (mkHomeConfigModule (mkMerge [
    {
      programs.zoxide.enable = true;
    }
  ]))
])
