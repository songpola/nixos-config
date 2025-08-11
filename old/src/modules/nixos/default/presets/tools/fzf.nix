{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
lib.${namespace}.mkPresetModule config [ "tools" "fzf" ] {
  systemConfig = [
    {
      # fzf - a command-line fuzzy finder
      # https://github.com/junegunn/fzf
      environment.systemPackages = [ pkgs.fzf ];
    }
  ];
  homeConfig = [
    {
      programs.fzf.enable = true;
    }
  ];
}
