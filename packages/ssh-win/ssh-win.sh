# Original command line arguments
args=("$@")

# Filter out the -oLocalCommand=echo started option
filtered_args=()
for arg in "${args[@]}"; do
  if [[ "$arg" != "-oLocalCommand=echo started" ]]; then
    filtered_args+=("$arg")
  else
    # Run the "echo started" here instead
    echo "started"
  fi
done

# Pass the filtered arguments
exec /mnt/c/Windows/System32/OpenSSH/ssh.exe "${filtered_args[@]}"
