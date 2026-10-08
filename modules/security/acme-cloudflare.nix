# ACME account for DNS-01 certificates through Cloudflare, shared by every ACME client on the host.
# NixOS' `security.acme` certificates (e.g. services.kanidm) inherit it from `security.acme.defaults`;
# services.caddy-reverse-proxy reads the same defaults for its own ACME client.
# The bare API token (Zone DNS edit) is a sops secret; the host passes the encrypted file in settings.
{ den, lib, ... }:
let
  secret = "acme-cloudflare/api-token";
in
{
  den.aspects.security.acme-cloudflare = {
    includes = [ den.aspects.programs.sops ];

    # For consumers that restart on token changes (`sops.secrets.<name>.restartUnits`)
    meta.tokenSecret = secret;

    settings = {
      email = lib.mkOption {
        type = lib.types.str;
        description = "ACME account email";
      };
      sopsFile = lib.mkOption {
        type = lib.types.path;
        description = "sops-encrypted file holding the bare Cloudflare API token";
      };
      key = lib.mkOption {
        type = lib.types.str;
        default = "cloudflare/API_TOKEN";
        description = "Key of the token inside `sopsFile`";
      };
    };

    nixos =
      { config, host, ... }:
      let
        cfg = host.settings.security.acme-cloudflare;
      in
      {
        sops.secrets.${secret} = { inherit (cfg) sopsFile key; };

        security.acme = {
          acceptTerms = true;
          defaults = {
            inherit (cfg) email;
            dnsProvider = "cloudflare";
            credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE = config.sops.secrets.${secret}.path;
          };
        };
      };
  };
}
