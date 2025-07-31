{
  lib,
  config,
  namespace,
  ...
}:
let
  secret = "binary-cache-private-key/prts-1";
  secretPath = config.sops.secrets.${secret}.path;
in
lib.${namespace}.mkPresetModule config [ "binary-cache" "server" ] {
  systemConfig = [
    {
      ${namespace}.presets.secrets = true;

      sops.secrets.${secret} = { };

      services.harmonia = {
        enable = true;
        signKeyPaths = [ secretPath ];
      };

      nix.settings.secret-key-files = [ secretPath ];

      networking.firewall.allowedTCPPorts = [ 5000 ];
    }
  ];
}
