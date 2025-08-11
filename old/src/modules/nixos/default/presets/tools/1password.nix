{
  lib,
  config,
  namespace,
  ...
}:
lib.${namespace}.mkPresetModule config [ "tools" "_1password" ] {
  systemConfig = [
    {
      # Enables the 1Password CLI
      programs._1password.enable = true;
    }
  ];
}
