{
  delib,
  const,
  host,
  ...
}:
delib.module {
  name = "jujutsu.integrations.wsl";

  options = delib.singleEnableOption host.isWsl;

  home.ifEnabled = delib.ifParentEnabled "jujutsu" {
    programs.jujutsu = {
      settings = {
        signing = {
          behavior = "own";
          backend = "ssh";
          backends.ssh.program = const.opSshSignWslPath;
          key = const.sshPublicKey;
        };
      };
    };
  };
}
