{_lib}: {
  users = {
    songpola = {
      openssh.authorizedKeys.keys = [
        _lib.sshPublicKey
      ];
      extraGroups = [
        "docker"
        "libvirtd"
      ];
    };
  };
}
