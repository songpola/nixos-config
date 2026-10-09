# Central auth on prts: Kanidm (identity provider) and oauth2-proxy (forward-auth gate for Caddy).
# Kanidm provisions the identity data below on every start; removing an entity here deletes it
# from Kanidm (provision.autoRemove). Credentials (passkeys) are not provisioned: enroll them
# through `kanidm person credential create-reset-token <name> -D idm_admin`.
# Apps gate on the prts_* groups, never on Kanidm's built-in ones (idm_admins etc. grant Kanidm
# admin rights, not app access): `caddy.import: auth prts_admins@idm.songpola.dev` (Kanidm sends
# groups by their SPN, `<name>@<domain>`).
{ den, lib, ... }:
let
  idmDomain = "idm.songpola.dev";
  authDomain = "auth.songpola.dev";
  clientId = "oauth2-proxy";
  clientSecret = den.aspects.services.oauth2-proxy.meta.clientSecret;
  # Groups as Kanidm sends them (SPN), for `import auth <group>`
  adminGroup = "prts_admins@${idmDomain}";
in
{
  den.hosts."x86_64-linux"."prts".settings.services = {
    kanidm = {
      # Upgrade one release at a time, see the option's description
      version = "1_11";
      domain = idmDomain;
      backupDir = "/tank/v2/services/kanidm/backups";
      sopsFile = ./secrets/auth.secrets.yaml;
    };

    oauth2-proxy = {
      domain = authDomain;
      cookieDomain = ".songpola.dev";
      oidcIssuerUrl = "https://${idmDomain}/oauth2/openid/${clientId}";
      inherit clientId;
      sopsFile = ./secrets/auth.secrets.yaml;
    };

    # Gated sites (the services themselves are in containers.nix)
    dozzle.forward-auth = {
      group = adminGroup;
      logoutUrl = "https://${authDomain}/oauth2/sign_out";
    };
    dockhand.forward-auth.group = adminGroup;
  };

  den.aspects."prts" = {
    includes = with den.aspects; [
      services.kanidm
      services.oauth2-proxy

      services.dozzle.forward-auth
      services.dockhand.forward-auth
    ];

    nixos =
      { config, ... }:
      {
        services.kanidm.provision = {
          groups = {
            prts_admins = { };
            prts_media = { };
          };

          persons.songpola = {
            displayName = "Songpol Anannetikul";
            # oauth2-proxy needs an email claim
            mailAddresses = [ "songpola@songpola.dev" ];
            groups = [
              "prts_admins"
              "prts_media"
            ];
          };

          systems.oauth2.${clientId} = {
            displayName = "PRTS";
            originUrl = "https://${authDomain}/oauth2/callback";
            originLanding = "https://${authDomain}/oauth2/start";
            basicSecretFile = config.sops.secrets.${clientSecret}.path;
            # preferred_username as the plain name, not the SPN
            preferShortUsername = true;
            # Only members of these groups can sign in at all; the gate then checks the group per site
            scopeMaps = lib.genAttrs [ "prts_admins" "prts_media" ] (_: [
              "openid"
              "email"
              "profile"
              "groups"
            ]);
          };
        };

        # Kanidm's copy of the client secret, read by provisioning
        sops.secrets.${clientSecret} = {
          owner = "kanidm";
          restartUnits = [ "kanidm.service" ];
        };
      };
  };
}
