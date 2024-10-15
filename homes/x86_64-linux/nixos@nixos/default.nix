{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
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
  ...
}: {
  home = {
    stateVersion = "24.05";
    packages = with pkgs; [
      # Install the LTS version of Node.js:
      # pnpm env use --global lts
      pnpm

      temurin-bin-21
    ];
  };

  programs = {
    # 1Password SSH WSL Integration
    git.extraConfig = {
      core.sshCommand = "ssh.exe";
      user.signingkey = lib.songpola.ssh-key;
      gpg.format = "ssh";
      gpg.ssh.program = "/mnt/c/Program Files/1Password/app/8/op-ssh-sign-wsl";
      commit.gpgsign = true;
    };

    # Nushell
    nushell = {
      enable = true;
      configFile.source = ./config.nu;
      shellAliases = {
        ssh = "ssh.exe";
        gcm = "czg emoji gpg";
        nos = "nh os switch";
      };
    };
    starship.enable = true;
    carapace.enable = true;
  };
}
