{
  lib,
  config,
  namespace,
  ...
}:
lib.${namespace}.mkPresetModule config [ "tools" "zoxide" ] {
  systemConfig = [
    {
      # zoxide - a smarter cd command
      # https://github.com/ajeetdsouza/zoxide
      programs.zoxide.enable = true;

      # zoxide uses fzf for completions / interactive selection
      ${namespace}.presets.tools.fzf = true;
    }
  ];
  homeConfig = [
    {
      programs.zoxide.enable = true;
    }
  ];
}
