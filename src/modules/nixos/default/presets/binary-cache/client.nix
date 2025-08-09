{
  lib,
  config,
  namespace,
  ...
}:
lib.${namespace}.mkPresetModule config [ "binary-cache" "client" ] {
  systemConfig = [
    {
      nix.settings = {
        substituters = [
          # NOTE: Don't use ssh-ng protocol here
          "ssh://prts" # prts.tail7623c.ts.net (SSH)
          "http://prts:5000" # prts.tail7623c.ts.net (Harmonia)
        ];
        trusted-public-keys = [
          lib.${namespace}.secrets.binary-cache-public-key.prts-1
        ];
      };
    }
  ];
}
