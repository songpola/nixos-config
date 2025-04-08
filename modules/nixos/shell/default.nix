{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
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
  inherit (lib) mkIf mkMerge mkBefore mkAfter readFile;
  inherit (lib.${namespace}) mkDefaultEnableOption;
  this = builtins.baseNameOf ./.;
  cfg = config.${namespace}.${this};

  envVars = {
    CARAPACE_BRIDGES = "fish";
    VISUAL = "code --wait";
    EDITOR = "micro";
    PAGER = "ov";
    BAT_PAGER = "ov -F -H3";
    MANPAGER = "ov --section-delimiter '^[^\\s]' --section-header";
    SYSTEMD_PAGER = "lnav";
    SYSTEMD_PAGERSECURE = "false"; # no need to set LESSSECURE=1 for ov pager
  };
  envVarsNushellOverride = {
    VISUAL = ["code" "--wait"];
  };
in {
  options.${namespace}.${this} = {
    enable = mkDefaultEnableOption "shell module";
  };
  config = mkIf cfg.enable {
    # Home Manager configs
    snowfallorg.users.${namespace}.home.config = {
      home = {
        packages = with pkgs; [
          uutils-coreutils-noprefix # coreutils replacement
          ov # pager
          lnav # log viewer
        ];
        shellAliases = {
          n = "nu";
          c = "clear";
          e = "exit";
        };
      };
      programs = {
        nushell = {
          enable = true;
          envFile.source = ./default_env.nu;
          configFile.source = ./default_config.nu;
          extraConfig = mkMerge [
            (mkBefore (readFile ./config.nu))
            (mkAfter (readFile ./external_completer.nu))
          ];
          environmentVariables = envVars // envVarsNushellOverride;
        };

        fish.enable = true; # use as completer

        bash = {
          enable = true;
          sessionVariables = envVars;
          initExtra = mkAfter ''
            # Use nushell in place of bash
            # keep this line at the bottom of ~/.bashrc
            command -v nu &> /dev/null && SHELL=$(command -v nu) exec nu
          '';
        };

        # completer
        carapace.enable = true;

        # prompt
        starship = {
          enable = true;
          settings = {
            shell.disabled = false;
            nix_shell.heuristic = true;
          };
        };

        # `cat` and `man` replacements
        bat = {
          enable = true;
          extraPackages = with pkgs.bat-extras; [
            batman
            batgrep
          ];
          config = {
            wrap = "never";
          };
        };

        # `ls` replacement
        eza = {
          enable = true;
          enableBashIntegration = true;
          enableNushellIntegration = true;
          extraOptions = [
            "-g"
            "--group-directories-first"
          ];
        };

        # `cd` replacement
        zoxide.enable = true;

        # `grep` replacement
        ripgrep.enable = true;

        # auto switch env
        direnv = {
          enable = true;
          nix-direnv.enable = true;
        };

        # text editor
        micro.enable = true;

        # `man` alternative
        tealdeer = {
          enable = true;
          settings.updates.auto_update = true;
        };

        # fuzzy finder
        fzf.enable = true;
      };
    };
  };
}
