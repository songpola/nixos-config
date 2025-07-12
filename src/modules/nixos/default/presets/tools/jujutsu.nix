{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkMerge;
  inherit (lib.${namespace}) mkHomeConfigModule githubUserEmail githubUserName;
in
lib.${namespace}.mkPresetModule config [ "tools" "jujutsu" ] (mkMerge [
  {
    environment.systemPackages = [ pkgs.jujutsu ];
  }
  (mkHomeConfigModule {
    programs.jujutsu = {
      enable = true;
      settings = {
        user = {
          email = githubUserEmail;
          name = githubUserName;
        };
      };
    };
  })
])
