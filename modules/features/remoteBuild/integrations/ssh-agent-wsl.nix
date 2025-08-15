{
  delib,
  username,
  ...
}:
delib.module {
  name = "remoteBuild.integrations.ssh-agent-wsl";

  options = delib.singleEnableOptionDependency "ssh.integrations.ssh-agent-wsl";

  nixos.ifEnabled = delib.ifParentEnabled "remoteBuild" (
    { myconfig, ... }:
    {
      # Use ssh-agent-wsl to connect to the remote build machine
      programs.ssh.extraConfig = ''
        Host ${myconfig.remoteBuild.hostName}
          User ${username}
          IdentityAgent ${myconfig.ssh.integrations.ssh-agent-wsl.sshAuthSock}
      '';
    }
  );
}
