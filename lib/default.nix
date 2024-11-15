{
  # This is the merged library containing your namespaced library as well as all libraries from
  # your flake's inputs.
  lib,
  # Your flake inputs are also available.
  # inputs,
  # The namespace used for your flake, defaulting to "internal" if not set.
  # namespace,
  # Additionally, Snowfall Lib's own inputs are passed. You probably don't need to use this!
  # snowfall-inputs,
}: let
  inherit (lib.snowfall.fs) safe-read-directory;
  inherit (lib) filterAttrs mapAttrsToList forEach flatten;
in rec {
  # Get a list of files in a directory that its kind matches the filter
  get-files = path: filter: let
    # Get all file entries in the directory
    entries = safe-read-directory path;
    # If there's no filter, return all entries
    # otherwise, filter the entries by the kind of the file
    filtered-entries =
      if filter == null
      then entries
      else filterAttrs (name: kind: filter kind) entries;
  in
    # Add the path to the name of the file
    mapAttrsToList (name: kind: "${path}/${name}") filtered-entries;

  # Make entries for wsl.extraBin from a list of packages
  make-extraBin-from-packages = packages: let
    paths = forEach packages (package: "${package}/bin");
    # Get a list of all files (no filter) in the path
    get-all-files = path: get-files path null;
    bins = flatten (forEach paths get-all-files);
  in
    forEach bins (src: {inherit src;});

  # Enable multiple options at once
  enableOptions = let
    op = acc: option: acc // {"${option}".enable = true;};
    acc0 = {};
  in
    options: lib.foldl' op acc0 options;
}
