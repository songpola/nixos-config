{ lib, ... }:
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

    # Using the default palette (catppuccin_mocha); no need to set anything.
  };
in
{
  den.aspects.programs.starship = {
    # NOTE: Custom starship integration.
    # The NixOS/HM options don't have Nushell integration.
    homeManager =
      { pkgs, config, ... }:
      let
        tomlFormat = pkgs.formats.toml { };
        settingsFile = tomlFormat.generate "starship.toml" settings;

        presetMergedSettingsFile =
          if presets == [ ] then
            settingsFile
          else
            # Merge the presets with the settings into a new TOML file, with the settings taking precedence
            pkgs.runCommand "starship.toml" { nativeBuildInputs = [ pkgs.yq ]; } ''
              tomlq -s -t 'reduce .[] as $item ({}; . * $item)' \
                ${
                  lib.concatStringsSep " " (
                    presets |> map (preset: "${pkgs.starship}/share/starship/presets/${preset}.toml")
                  )
                } \
                ${settingsFile} \
                > $out
            '';

        configPath = "${config.xdg.configHome}/starship.toml";
      in
      {
        home = {
          packages = [ pkgs.starship ];

          file.${configPath}.source = presetMergedSettingsFile;

          sessionVariables.STARSHIP_CONFIG = configPath;
        };
      };

    _.bash-prompt.homeManager =
      { pkgs, ... }:
      {
        programs.bash.initExtra = ''
          if [[ $TERM != "dumb" && $TERM != "linux" ]]; then
            eval "$(${lib.getExe pkgs.starship} init bash --print-full-init)"
          fi
        '';
      };

    _.nushell-prompt.homeManager =
      { pkgs, ... }:
      {
        programs.nushell.extraConfig =
          let
            starshipInitNu = pkgs.runCommand "starship-nushell-config.nu" { } ''
              ${lib.getExe pkgs.starship} init nu >> $out
            '';
          in
          ''
            if ($env.TERM != "dumb" and $env.TERM != "linux") {
                source ${starshipInitNu}
            }
          '';
      };
  };
}
