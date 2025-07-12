{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkMerge;
  inherit (lib.${namespace}) mkHomeConfigModule;
in
lib.${namespace}.mkPresetModule config [ "tools" "eza" ] (mkMerge [
  (mkHomeConfigModule (mkMerge [
    {
      # eza - A modern replacement for ls.
      # https://github.com/eza-community/eza
      programs.eza = {
        enable = true;
        enableNushellIntegration = true; # idk why but this is false by default
        extraOptions = [
          "-g" # list each file's group
          "--group-directories-first"
        ];
      };
    }
  ]))
])
