{ den, lib, ... }:
{
  # Hosts opt in with `zfs.enable = true;` (a host fact other aspects read) and tune the
  # aspect through `settings.zfs`.
  den.schema.host.imports = [
    {
      options.zfs.enable = lib.mkEnableOption "ZFS support (includes the zfs aspect)";
    }
  ];

  den.policies.zfs-on-host =
    { host, ... }:
    lib.optional (host.class == "nixos" && host.zfs.enable) (den.lib.policy.include den.aspects.zfs);
  den.schema.host.includes = [ den.policies.zfs-on-host ];

  den.aspects.zfs.settings = {
    hostId = lib.mkOption {
      type = lib.types.strMatching "[0-9a-f]{8}";
      description = "networking.hostId; ZFS refuses to import pools without a unique 8-hex-digit ID";
    };
    extraPools = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Pools to import after boot (boot.zfs.extraPools)";
    };
  };

  den.aspects.zfs.nixos =
    { host, ... }:
    let
      cfg = host.settings.zfs;
    in
    {
      networking.hostId = cfg.hostId;

      boot.supportedFilesystems = [ "zfs" ];

      boot.zfs = {
        inherit (cfg) extraPools;

        devNodes = "/dev/disk/by-id";

        # Forcibly import the ZFS root pool(s) during early boot.
        #
        # This is enabled by default for backwards compatibility purposes,
        # but it is HIGHLY RECOMMENDED to DISABLE this option,
        # as it bypasses some of the safeguards ZFS uses to protect your ZFS pools.
        #
        # If you set this option to false and NixOS subsequently fails to boot because it cannot import the root pool,
        # you should boot with the zfs_force=1 option as a kernel parameter (e.g. by manually editing the kernel params in grub during boot).
        # You should only need to do this once.
        forceImportRoot = false;
      };

      services.zfs = {
        autoScrub.enable = true;
        trim.enable = true;
      };
    };
}
