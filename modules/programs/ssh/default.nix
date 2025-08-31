{
  delib,
  ...
}:
delib.module {
  name = "ssh";

  options = delib.singleEnableOption false;

  home.ifEnabled = {
    programs.ssh = {
      enable = true;

      # Enable SSH connection multiplexing
      controlMaster = "auto";
      controlPersist = "10m";

      matchBlocks = {
        "gitea.songpola.dev" = {
          port = 2222;
        };
      };
    };
  };
}
