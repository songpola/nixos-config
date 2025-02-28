{_lib}: {
  enable = true;
  users = ["songpola"];
  inherit (_lib.opnix) configFile;
}
