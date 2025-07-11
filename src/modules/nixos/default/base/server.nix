{
  lib,
  config,
  namespace,
  ...
}:
lib.${namespace}.mkBaseModule config "server" {
  # Bootable EFI system
  ${namespace}.presets.bootable = true;

  # Remote access
  services.openssh.enable = true;
  users.users.${namespace}.openssh.authorizedKeys.keys = [ lib.sshPublicKey ];
}
