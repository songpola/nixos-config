{
  delib,
  host,
  ...
}:
delib.module {
  name = "server";

  options = delib.singleEnableOption host.isServer;

  myconfig.ifEnabled.sshd.enable = true;
}
