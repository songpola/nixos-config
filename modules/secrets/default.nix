{
  delib,
  inputs,
  config,
  ...
}:
delib.module {
  name = "secrets";

  options = delib.singleEnableOption false;

  myconfig.always.args.shared = {
    inherit (config.sops) secrets;
  };

  nixos.always.imports = [ inputs.sops-nix.nixosModules.sops ];

  nixos.ifEnabled = {
    sops = {
      # This will add secrets.yml to the nix store
      # You can avoid this by adding a string to the full path instead, i.e.
      # sops.defaultSopsFile = "/root/.sops/secrets/example.yaml";
      defaultSopsFile = ./secret.yaml;

      # This will automatically import SSH keys as age keys
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
  };
}
