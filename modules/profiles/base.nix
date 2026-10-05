{ den, ... }:
{
  den.aspects.profiles.base = {
    includes = with den.aspects.programs; [
      # Nix tools
      nh

      # Shells
      nushell
      nushell.auto-exec-from-bash-on-login

      # Shell prompts
      starship
      starship.bash-prompt
      starship.nushell-prompt

      # Shell history utilities
      atuin

      # Shell completion utilities
      carapace

      # Shell extensions
      direnv

      # Editors
      micro
      micro.default-editor
      vscode-remote-support

      # VCS
      git
      jujutsu

      # Pagers
      ov
      ov.default-pager
      ov.default-pager-for-systemd
      delta
      delta.default-pager-for-git
      delta.default-pager-for-jujutsu

      # Modern drop-in replacement tools
      eza # replace ls
      bat # replace cat
      zoxide # cd enhancement

      # SSH settings
      ssh

      # Terminal multiplexers
      zellij

      # Sysadmin tools
      btop
      isd
    ];

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          # Nix tools
          nix-output-monitor
          nil
          nixfmt # former nixfmt-rfc-style
          dix

          # Sysadmin tools
          lsof
          fastfetch

          # Modern drop-in replacement tools
          ripgrep # replace grep
          fd # replace find
          duf # replace df
          dust # replace du
          procs # replace ps
          httpie # replace curl
          doggo # replace dig
          ouch # replace zip
          just # replace make

          # Utilities
          jq
          yq

          # Terminal file managers
          yazi
        ];
      };
  };
}
