{
  delib,
  const,
  username,
  ...
}:
delib.module {
  name = "sshd";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    services.openssh.enable = true;
    users.users.${username}.openssh.authorizedKeys.keys = [ const.sshPublicKey ];
  };
}
