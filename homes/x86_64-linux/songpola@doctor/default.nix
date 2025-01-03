{
  # # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # # as well as the libraries available from your flake's inputs.
  lib,
  # # An instance of `pkgs` with your overlays and packages applied is also available.
  # pkgs,
  # # You also have access to your flake's inputs.
  # inputs,
  # # Additional metadata is provided by Snowfall Lib.
  # # Additional metadata is provided by Snowfall Lib.
  # ---
  # Infinite recursion when using namespace in home configuration
  # https://github.com/snowfallorg/lib/issues/142
  #
  # namespace, # The namespace used for your flake, defaulting to "internal" if not set.
  # ---
  # system, # The system architecture for this host (eg. `x86_64-linux`).
  # target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  # format, # A normalized name for the system target (eg. `iso`).
  # virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  # systems, # An attribute map of your defined hosts.
  # # All other arguments come from the system system.
  # config,
  ...
}: {
  programs.git.extraConfig = {
    commit.gpgsign = true;
    core.sshCommand = "ssh.exe";
    gpg.format = "ssh";
    gpg.ssh.program = "/mnt/c/Users/songpola/AppData/Local/1Password/app/8/op-ssh-sign-wsl";
    user.signingkey = lib.songpola.sshPublicKey;
  };
}
