{_lib}: {
  extraConfig = {
    commit.gpgsign = true;
    core.sshCommand = "ssh.exe";
    gpg.format = "ssh";
    gpg.ssh.program = "/mnt/c/Users/songpola/AppData/Local/1Password/app/8/op-ssh-sign-wsl";
    user.signingkey = _lib.public.ssh;
  };
}
