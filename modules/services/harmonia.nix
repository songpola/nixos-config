{
  delib,
  config,
  const,
  ...
}:
let
  secret = const.prts.binaryCache.privateKeySecret;
  secretPath = config.sops.secrets.${secret}.path;
in
delib.module {
  name = "harmonia";

  options = delib.singleEnableOption false;

  myconfig.ifEnabled = {
    secrets.enable = true;
  };

  nixos.ifEnabled = {
    sops.secrets.${secret} = { };

    services.harmonia = {
      enable = true;
      signKeyPaths = [ secretPath ];
    };

    networking.firewall.allowedTCPPorts = [ 5000 ];
  };
}
