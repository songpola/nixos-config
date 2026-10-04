{ den, lib, ... }:
let
  userName = "Songpol Anannetikul";
  userEmail = "ice.songpola@pm.me";

  # 1Password's SSH signing helper on the Windows host, used by git and jj
  # under WSL.
  opSshSignPath = "/mnt/c/Users/songpola/AppData/Local/Microsoft/WindowsApps/op-ssh-sign-wsl.exe";

  sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSjfctCxjS+/jDcVERwcTN6wP+GaScfSo4VtfsmagOz songpola";
in
{
  # den.schema.user = {
  #   options.sshPublicKey = lib.mkOption {
  #     type = lib.types.nullOr lib.types.str;
  #     default = null;
  #     description = "The user's SSH public key (commit signing, ...).";
  #   };
  #   options.authorizedKeys = lib.mkOption {
  #     type = lib.types.listOf lib.types.str;
  #     default = [ ];
  #     description = "SSH public keys allowed to log in as this user (see `programs.ssh-server`).";
  #   };
  # };

  den.aspects.songpola = {
    includes = [
      den.aspects.primary-user

      # Per-user, not `den.aspects.wsl`: that hook applies to every
      # user on a WSL host, and this signing setup is specific to songpola.
      den.aspects.songpola.wsl-commit-signing

      # (
      #   { host, user }:
      #   {
      #     name = "dialout-group(${user.name}@${host.name})";

      #     # See https://wiki.nixos.org/wiki/Serial_Console#Unprivileged_access_to_serial_device
      #     user.extraGroups = [ "dialout" ];
      #   }
      # )
    ];

    user.openssh.authorizedKeys.keys = [ sshPublicKey ];

    homeManager.programs.git.settings = {
      user.name = userName;
      user.email = userEmail;
      init.defaultBranch = "main";
      merge.conflictstyle = "zdiff3";
    };

    _.wsl-commit-signing =
      { host }:
      {
        includes = lib.optionals (host.wsl.enable or false) [
          den.aspects.songpola.git-commit-signing
          den.aspects.songpola.jj-commit-signing
        ];
      };

    # Commit signing with an SSH key held by 1Password on the Windows host.
    _.git-commit-signing =
      { user, ... }:
      {
        homeManager.programs.git.signing = {
          signByDefault = true;
          format = "ssh";
          signer = opSshSignPath;
          key = sshPublicKey;
        };
      };

    # User-level memory for Claude Code (~/.claude/CLAUDE.md), loaded in every project.
    # Only written on hosts that include `programs.claude-code`.
    homeManager.programs.claude-code.context = ''
      # Personal preferences

      - System: hosts run NixOS (some under WSL). Don't use apt, pip
        install, npm -g, curl | sh, etc. If a tool is missing, get it from
        nixpkgs for one-off use: `nix shell nixpkgs#<pkg> -c <cmd>` or
        `nix run nixpkgs#<pkg> -- <args>` (`nix-locate bin/<cmd>` finds the
        package). Tools needed permanently belong in the NixOS config.
        Flake registry: `nixpkgs` is the system's pinned stable nixpkgs;
        `unstable` is an alias for `github:NixOS/nixpkgs/nixos-unstable`
        (e.g. `nix shell unstable#<pkg>` for a newer version).
      - Tool lookup order: (1) use what is already on PATH; (2) otherwise
        `nix shell nixpkgs#<pkg>` (reuses the pinned nixpkgs, no re-download);
        (3) only if the pinned nixpkgs lacks the needed version, fall back to
        omnibin, a lazy store of every binary nixpkgs ever shipped:
        `nix run github:fzakaria/omnibin -- <cmd>@<version> <args>` (e.g.
        `python3@3.6.2 -c 'print(1)'`). Find versions with
        `nix run github:fzakaria/omnibin -- omnibin which --all <cmd>`.
        Omnibin only runs prebuilt binaries: no `nix build`, and no
        `python3.withPackages`-style environments.
      - Version control: I use jujutsu (`jj`), not git. Repos are colocated
        jj + git. Use `jj` for status, diff, log, commits, bookmarks and
        pushing; read-only `git` commands are fine only when jj has no
        equivalent. Don't create git branches or commits directly.
      - Shell: my interactive shell is nushell. Commands, snippets and
        scripts meant for me to run should be nushell syntax. (Your own
        Bash tool still runs bash; that's fine.)
    '';

    # Personal Claude Code skills. Linked one by one, so ~/.claude/skills itself
    # stays writable (Claude Code keeps synced skills there too).
    homeManager.programs.claude-code.skills = {
      jj-commit = ./claude-skills/jj-commit;
    };

    homeManager.programs.jujutsu.settings = {
      user.name = userName;
      user.email = userEmail;

      # Use Git's "diff3" style conflict markers (not zdiff3; not support yet)
      ui.conflict-marker-style = "git";

      ui.editor = "code -w";
      ui.diff-editor = "code";
      ui.merge-editor = "code";

      merge-tools.code = {
        diff-args = [
          "--wait"
          "--diff"
          "$left"
          "$right"
        ];
        diff-invocation-mode = "file-by-file";
        edit-args = [
          "--wait"
          "--diff"
          "$left"
          "$right"
        ];
        edit-invocation-mode = "file-by-file";
      };
    };

    _.jj-commit-signing =
      { user, ... }:
      {
        homeManager.programs.jujutsu.settings = {
          signing = {
            behavior = "own";
            backend = "ssh";
            backends.ssh.program = opSshSignPath;
            key = sshPublicKey;
          };
          git.sign-on-push = true;
        };
      };
  };
}
