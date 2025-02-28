{_lib}: {
  enable = true;
  users = [ "songpola" ];
  configFile = _lib.secrets.opnix;
}
