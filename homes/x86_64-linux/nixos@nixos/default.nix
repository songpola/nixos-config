{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  # lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  # inputs,
  # Additional metadata is provided by Snowfall Lib.
  # home, # The home architecture for this host (eg. `x86_64-linux`).
  # target, # The Snowfall Lib target for this home (eg. `x86_64-home`).
  # format, # A normalized name for the home target (eg. `home`).
  # virtual, # A boolean to determine whether this home is a virtual target using nixos-generators.
  # host, # The host name for this home.
  # All other arguments come from the home home.
  # config,
  homeStateVersion, # specialArgs
  ...
}: {
  home.stateVersion = homeStateVersion;
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    micro
  ];

  programs.git = {
    enable = true;
    userEmail = "1527535+songpola@users.noreply.github.com";
    userName = "Songpol Anannetikul";
    extraConfig = {
      init.defaultBranch = "main";

      core.sshCommand = "ssh.exe";
      user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSjfctCxjS+/jDcVERwcTN6wP+GaScfSo4VtfsmagOz";
      gpg.format = "ssh";
      gpg.ssh.program = "/mnt/c/Program Files/1Password/app/8/op-ssh-sign-wsl";
      commit.gpgsign = true;
    };
  };
}
