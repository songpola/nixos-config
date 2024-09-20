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
}: {
  # Get a list of files in a directory that its kind matches the filter
  get-files = path: filter: let
    # Get all file entries in the directory
    entries = lib.snowfall.fs.safe-read-directory path;
    # If there's no filter, return all entries
    # otherwise, filter the entries by the kind of the file
    filtered-entries =
      if filter == null
      then entries
      else lib.filterAttrs (name: kind: filter kind) entries;
  in
    # Add the path to the name of the file
    lib.attrsets.mapAttrsToList (name: kind: "${path}/${name}") filtered-entries;
}
