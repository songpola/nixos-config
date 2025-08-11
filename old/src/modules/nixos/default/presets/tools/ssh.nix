{
  lib,
  config,
  namespace,
  ...
}:
lib.${namespace}.mkPresetModule config [ "tools" "ssh" ] {
  systemConfig = [
    {
      # Enable ssh-agent-wsl preset (WSL only)
      ${namespace}.presets.services.ssh-agent-wsl = true;
    }
  ];
  homeConfig = [
    {
      # Enable SSH connection multiplexing
      programs.ssh = {
        enable = true;
        controlMaster = "auto";
        controlPersist = "10m";
      };
    }
  ];
}
