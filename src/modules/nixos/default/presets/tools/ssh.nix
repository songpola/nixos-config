{
  lib,
  config,
  namespace,
  ...
}:
lib.${namespace}.mkPresetModule2 config [ "tools" "ssh" ] {
  systemConfig = [
    {
      # Enable ssh-agent-wsl preset (WSL only)
      ${namespace}.presets.tools.ssh-agent-wsl = true;
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
