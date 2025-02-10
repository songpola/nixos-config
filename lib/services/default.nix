{
  # # This is the merged library containing your namespaced library as well as all libraries from
  # # your flake's inputs.
  # lib,
  # # Your flake inputs are also available.
  # inputs,
  # # The namespace used for your flake, defaulting to "internal" if not set.
  # namespace,
  # # Additionally, Snowfall Lib's own inputs are passed. You probably don't need to use this!
  # snowfall-inputs,
}: {
  mkSyncthingConfig = config: username: let
    _user = config.users.users.${username};
  in {
    enable = true;
    user = username;
    group = _user.group;
    dataDir = _user.home;
    configDir = _user.home + "/.local/state/syncthing"; # XDG_STATE_HOME
    overrideDevices = false;
    overrideFolders = false;
  };
}
