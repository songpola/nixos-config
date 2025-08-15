{
  delib,
  lib,
  pkgs,
  homeconfig,
  ...
}:
let
  presets = [
    "catppuccin-powerline"
    "nerd-font-symbols"
  ];
  settings = {
    # Enable line breaks for two-line prompts.
    # `disabled = true` by default from catppuccin-powerline preset.
    line_break.disabled = false;
    os.disabled = false;
    shell.disabled = false;
    username.format = "[ $user@]($style)";
    hostname = {
      ssh_only = false;
      ssh_symbol = " ";
      style = "bg:red fg:crust";
      format = "[$hostname$ssh_symbol ]($style)";
    };

    # Add $shell to the prompt
    format =
      ''
        [](red)
        $os
        $username
        $hostname
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
                presets |> map (preset: "${pkgs.starship}/share/starship/presets/${preset}.toml")
              )
            } \
            ${settingsFile} \
            > $out
        '';

  configPath = "${homeconfig.xdg.configHome}/starship.toml";
in
delib.module {
  name = "starship.settings";

  options = delib.singleEnableOption false;

  home.ifEnabled = delib.ifParentEnabled "starship" {
    home = {
      sessionVariables.STARSHIP_CONFIG = configPath;

      file.${configPath} = lib.mkIf (settings != { }) {
        source = finalSettingsFile;
      };
    };
  };
}
