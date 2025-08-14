{
  delib,
  host,
  config,
  const,
  ...
}:
let
  secret = const.prts.binaryCache.privateKeySecret;
  secretPath = config.sops.secrets.${secret}.path;
in
delib.module {
  name = "binaryCache.server";

  options = delib.singleEnableOption host.cacheServerFeatured;

  myconfig.ifEnabled = {
    secrets.enable = true;
    harmonia.enable = true;
  };

  nixos.ifEnabled = {
    sops.secrets.${secret} = { };

    nix.settings.secret-key-files = [ secretPath ];
  };
}
