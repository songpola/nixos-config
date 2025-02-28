{
  # # https://snowfall.org/guides/lib/library/
  # # This is the merged library containing your namespaced library as well as all libraries from
  # # your flake's inputs.
  lib,
  # # Your flake inputs are also available.
  # inputs,
  # # The namespace used for your flake, defaulting to "internal" if not set.
  namespace,
  # # Additionally, Snowfall Lib's own inputs are passed. You probably don't need to use this!
  # snowfall-inputs,
}: {
  opnix = {
    configFile = ./opnix/secrets.json;
    mkSecretPath = config: secret: "${config.services.onepassword-secrets.outputDir}/${secret}";
  };
  sops-nix = {
    defaultSopsFile = ./sops-nix/secrets.yaml;
    mkSecretPath = config: secret: config.sops.secrets.${secret}.path;
  };
}
