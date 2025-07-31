{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) getSecretsPath;
in
lib.${namespace}.mkPresetModule config [ "secrets" ] {
  systemConfig = [
    {
      sops = {
        # This will add secrets.yml to the nix store
        # You can avoid this by adding a string to the full path instead, i.e.
        # sops.defaultSopsFile = "/root/.sops/secrets/example.yaml";
        defaultSopsFile = getSecretsPath "/secret.yaml";

        # This will automatically import SSH keys as age keys
        age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      };
    }
  ];
}
