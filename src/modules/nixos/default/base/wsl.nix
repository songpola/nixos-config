{
  lib,
  config,
  namespace,
  ...
}:
lib.${namespace}.mkBaseModule config "wsl" {
  wsl.enable = true;
  wsl.defaultUser = namespace; # songpola
}
