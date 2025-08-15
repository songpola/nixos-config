{
  delib,
  host,
  const,
  secrets,
  ...
}:
let
  secret = const.prts.binaryCache.privateKeySecret;
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

    nix.settings.secret-key-files = [ secrets.${secret}.path ];
  };
}
