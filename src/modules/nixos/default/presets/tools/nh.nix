{
  lib,
  config,
  namespace,
  ...
}:
lib.${namespace}.mkPresetModule config [ "tools" "nh" ] {
  systemConfig = [
    {
      # nh - Yet another Nix CLI helper
      # https://github.com/nix-community/nh
      #
      # NOTE: No need to use the options from Home Manager,
      # because all the profiles (system and user) will be cleaned by this options.
      programs.nh = {
        enable = true;
        clean.enable = true; # auto clean (all) (default: weekly)
        flake = lib.${namespace}.nixosConfigPath;
      };
    }
  ];
  extraConfig = [
    (lib.${namespace}.mkIfBaseEnabled config "server" {
      systemConfig = [
        {
          # Servers would have plenty of storage.
          # So we can keep the cache for a long time.
          programs.nh.clean.extraArgs =
            [
              "--keep=10" # keep at least 10 generations
              "--keep-since=1m" # keep gcroots and generations in the last 1 month
              "--nogc" # don't run `nix store --gc`
              "--nogcroots" # don't clean gcroots
            ]
            |> lib.concatStringsSep " ";
        }
      ];
    })
  ];
}
