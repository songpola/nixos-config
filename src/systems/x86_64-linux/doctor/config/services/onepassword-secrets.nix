{_lib}: {
  enable = true;
  users = ["songpola"];
  inherit (_lib.secrets.opnix) configFile;
}
