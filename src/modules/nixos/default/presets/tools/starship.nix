{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  presets = [
    "catppuccin-powerline"
    "nerd-font-symbols"
  ];
  settings = {
    # Enable line breaks for two-line prompts.
    # `disabled = true` by default from catppuccin-powerline preset.
    line_break.disabled = false;
    # Enable showing current OS symbol
    os.disabled = false;
    # Enable showing current shell symbol
    shell.disabled = false;

    # Add $shell to the prompt
    format =
      ''
        [](red)
        $os
        $username
        [](bg:peach fg:red)
        $directory
        [](bg:yellow fg:peach)
        $git_branch
        $git_status
        [](fg:yellow bg:green)
        $c
        $rust
        $golang
        $nodejs
        $php
        $java
        $kotlin
        $haskell
        $python
        [](fg:green bg:sapphire)
        $conda
        [](fg:sapphire bg:lavender)
        $time
        [ ](fg:lavender)
        $cmd_duration
        $line_break
        $shell
        $character
      ''
      |> lib.replaceString "\n" ""; # remove newlines
  };

  package = pkgs.starship;
  tomlFormat = pkgs.formats.toml { };
  settingsFile = tomlFormat.generate "starship.toml" settings;
  finalSettingsFile =
    if presets == [ ] then
      settingsFile
    else
      pkgs.runCommand "starship.toml"
        {
          nativeBuildInputs = [ pkgs.yq ];
        }
        ''
          tomlq -s -t 'reduce .[] as $item ({}; . * $item)' \
            ${
              lib.concatStringsSep " " (
                presets |> map (preset: "${package}/share/starship/presets/${preset}.toml")
              )
            } \
            ${settingsFile} \
            > $out
        '';
in
lib.${namespace}.mkPresetModule config [ "tools" "starship" ] {
  # starship - a cross-shell prompt
  # https://github.com/starship/starship
  #
  # NOTE: Custom starship integration implementation.
  # The NixOS options don't have Nushell integration and
  # the current Nushell integration in Home Manager is too old (since 2022).
  #
  # TODO: Implement custom system-wide integration
  homeConfig = homeCfg: [
    ({
      home =
        let
          configPath = "${homeCfg.xdg.configHome}/starship.toml";
        in
        {
          packages = [ package ];

          sessionVariables.STARSHIP_CONFIG = configPath;

          file.${configPath} = mkIf (settings != { }) {
            source = finalSettingsFile;
          };
        };

      programs.bash.initExtra = ''
        if [[ $TERM != "dumb" && $TERM != "linux" ]]; then
          eval "$(${lib.getExe package} init bash --print-full-init)"
        fi
      '';

      programs.nushell.extraConfig =
        let
          starshipInit = pkgs.runCommand "starship-nushell-config.nu" { } ''
            ${lib.getExe config.programs.starship.package} init nu >> "$out"
          '';
        in
        ''
          if ($env.TERM != "dumb" and $env.TERM != "linux") {
              source ${starshipInit}
          }
        '';
    })
  ];
}
