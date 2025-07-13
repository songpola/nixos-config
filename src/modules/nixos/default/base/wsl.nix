{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
lib.${namespace}.mkBaseModule config "wsl" {
  wsl = {
    enable = true;
    defaultUser = namespace; # songpola
  };

  # Enable xdg-open for opening files and URLs in WSL
  environment.systemPackages = [ pkgs.xdg-utils ];
}
