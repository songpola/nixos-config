{
  delib,
  const,
  host,
  ...
}:
delib.module {
  name = "git.integrations.wsl";

  options = delib.singleEnableOption host.isWsl;

  home.ifEnabled = delib.ifParentEnabled "git" {
    programs.git = {
      extraConfig = {
        # Use the 1Password SSH agent with WSL integration
        core.sshCommand = "/mnt/c/Windows/System32/OpenSSH/ssh.exe";
      };

      # Sign commits with SSH key
      signing = {
        signByDefault = true;
        format = "ssh";
        signer = const.opSshSignWslPath;
        key = const.sshPublicKey;
      };
    };
  };
}
