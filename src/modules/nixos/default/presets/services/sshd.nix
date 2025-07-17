{
  lib,
  config,
  namespace,
  ...
}:
lib.${namespace}.mkPresetModule config [ "services" "sshd" ] {
  systemConfig = [
    {
      services.openssh.enable = true;
      users.users.${namespace}.openssh.authorizedKeys.keys = [
        lib.${namespace}.sshPublicKey
      ];
    }
  ];
}
