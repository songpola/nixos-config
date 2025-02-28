{_lib}: {
  users = {
    songpola = {
      openssh.authorizedKeys.keys = [
        _lib.public.ssh
      ];
      extraGroups = [
        "docker"
        "libvirtd"
      ];
    };
  };
}
