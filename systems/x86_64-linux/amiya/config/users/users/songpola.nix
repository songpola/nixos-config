{lib, ...}: {
  openssh.authorizedKeys.keys = [
    lib.songpola.sshPublicKey
  ];
}
