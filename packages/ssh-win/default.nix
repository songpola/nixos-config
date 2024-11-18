{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  # lib,
  # You also have access to your flake's inputs.
  # inputs,
  # The namespace used for your flake, defaulting to "internal" if not set.
  # namespace,
  # All other arguments come from NixPkgs. You can use `pkgs` to pull packages or helpers
  # programmatically or you may add the named attributes as arguments here.
  pkgs,
  # stdenv,
  ...
}:
pkgs.writeShellScriptBin "ssh-win"
''
  # Code to execute before calling ssh
  echo "Running ssh-win..."
  # Example: Logging the connection attempt
  echo "$(date): Attempting to connect: $@"

  # Call the actual ssh command with all passed arguments
  # ${pkgs.openssh}/bin/ssh "$@"

  # Prepare the command for PowerShell
  powershell_cmd="ssh $*"

  # Call PowerShell.exe to execute the ssh command
  # /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -Command
  /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -Command "$powershell_cmd"

  # Capture the exit code from PowerShell
  exit_code=$?

  # Optional: Handle exit codes or log further
  if [ $exit_code -ne 0 ]; then
    echo "SSH command failed with exit code $exit_code"
  fi

  # Return the exit code from PowerShell
  exit $exit_code
''
