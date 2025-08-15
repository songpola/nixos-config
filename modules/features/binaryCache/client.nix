{
  delib,
  host,
  const,
  ...
}:
delib.module {
  name = "binaryCache.client";

  options = delib.singleEnableOption host.cacheClientFeatured;

  nixos.ifEnabled = {
    nix.settings = {
      substituters = [
        # NOTE: Don't use ssh-ng protocol here
        "ssh://prts.tail7623c.ts.net" # SSH
        "http://prts.tail7623c.ts.net:5000" # Harmonia
      ];
      trusted-public-keys = [ const.prts.binaryCache.publicKey ];
    };
  };
}
