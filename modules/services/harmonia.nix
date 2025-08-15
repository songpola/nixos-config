{
  delib,
  const,
  secrets,
  ...
}:
let
  secret = const.prts.binaryCache.privateKeySecret;
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
      signKeyPaths = [ secrets.${secret}.path ];
    };

    networking.firewall.allowedTCPPorts = [ 5000 ];
  };
}
