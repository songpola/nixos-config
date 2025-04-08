{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  # pkgs,
  # You also have access to your flake's inputs.
  # inputs,
  # Additional metadata is provided by Snowfall Lib.
  namespace, # The namespace used for your flake, defaulting to "internal" if not set.
  # system, # The system architecture for this host (eg. `x86_64-linux`).
  # target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  # format, # A normalized name for the system target (eg. `iso`).
  # virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  # systems, # An attribute map of your defined hosts.
  # All other arguments come from the module system.
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkMerge;
  inherit (lib.${namespace}) public mkDefaultEnableOption mkHomeConfig;
  this = builtins.baseNameOf ./.;
  cfg = config.${namespace}.${this};
in {
  options.${namespace}.${this} = {
    enable = mkDefaultEnableOption "Git default config";
    use1PasswordWSL = mkEnableOption "the 1Password SSH agent with WSL integration";
  };
  config = mkIf cfg.enable (mkHomeConfig {
    programs.git = {
      enable = true;
      userEmail = "1527535+songpola@users.noreply.github.com";
      userName = "Songpol Anannetikul";
      extraConfig = mkMerge [
        {
          init.defaultBranch = "main";
        }
        (mkIf cfg.use1PasswordWSL {
          # Use the 1Password SSH agent with WSL integration
          core.sshCommand = "ssh.exe";
          # Sign Git commits with SSH
          commit.gpgsign = true;
          gpg.format = "ssh";
          gpg.ssh.program = "/mnt/c/Users/songpola/AppData/Local/1Password/app/8/op-ssh-sign-wsl";
          user.signingkey = public.ssh;
        })
      ];
    };
  });
}
