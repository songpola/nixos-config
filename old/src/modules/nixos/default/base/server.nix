{
  lib,
  config,
  namespace,
  ...
}:
lib.${namespace}.mkBaseModule config "server" {
  ${namespace}.presets = {
    bootable = true;
    services = {
      sshd = true;
    };
  };

  nix.settings = {
    # To prevent the `error: cannot ... because it lacks a signature by a trusted key`
    trusted-users = [ namespace ];
  };
}
