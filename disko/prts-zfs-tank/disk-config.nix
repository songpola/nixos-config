let
  mkPartlabel = d: p: "/dev/disk/by-partlabel/disk-${d}-${p}";
in {
  disko.devices = {
    disk = {
      ssd = {
        device = "/dev/disk/by-id/nvme-WD_Blue_SN570_1TB_231429804094_1";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            zspecial = {
              end = "-16G";
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
            zlog = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };
      hdd = {
        device = "/dev/disk/by-id/ata-ST2000DM005-2U9102_WFM449L2";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };
    };
    zpool = {
      tank = {
        type = "zpool";
        mode = {
          topology = {
            type = "topology";
            vdev = [
              {
                members = ["hdd"];
              }
            ];
            log = [
              {
                members = [(mkPartlabel "ssd" "zlog")];
              }
            ];
            special = [
              {
                members = [(mkPartlabel "ssd" "zspecial")];
              }
            ];
          };
        };
        options = {
          ashift = "12";
        };
        rootFsOptions = {
          xattr = "sa";
          special_small_blocks = "128k";
        };
        mountpoint = "/mnt/tank";
        datasets = {
          docker = {
            type = "zfs_fs";
            mountpoint = "/var/lib/docker";
          };
          data.type = "zfs_fs";
          "data/docker".type = "zfs_fs";
          "data/docker/affine".type = "zfs_fs";
          "data/docker/affine/config".type = "zfs_fs";
          "data/docker/affine/db-data" = {
            type = "zfs_fs";
            options = {
              recordsize = "16K"; # Matches PostgreSQL page size
              compression = "lz4"; # Fast and efficient compression
              atime = "off"; # Avoid extra writes for access time updates
              logbias = "throughput"; # Balance between latency and throughput
              primarycache = "all"; # Cache both metadata and data
              secondarycache = "all"; # Optimize for read performance
            };
          };
          "data/docker/affine/upload" = {
            type = "zfs_fs";
            options = {
              recordsize = "1M";
              compression = "zst";
              atime = "off";
            };
          };
          "data/docker/dockge".type = "zfs_fs";
          "data/docker/nocodb".type = "zfs_fs";
          "data/docker/nocodb/db-data" = {
            type = "zfs_fs";
            options = {
              recordsize = "16K"; # Matches PostgreSQL page size
              compression = "lz4"; # Fast and efficient compression
              atime = "off"; # Avoid extra writes for access time updates
              logbias = "throughput"; # Balance between latency and throughput
              primarycache = "all"; # Cache both metadata and data
              secondarycache = "all"; # Optimize for read performance
            };
          };
        };
      };
    };
  };
}
