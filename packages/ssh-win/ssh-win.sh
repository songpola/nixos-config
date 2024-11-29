for arg in "$@"; do
  if [ "$arg" = "-oLocalCommand=echo started" ]; then
    echo "started"
    break
  fi
done

# $ nix copy --to ssh://songpola@10.0.1.101 nixpkgs#hello -vvvvv
# error: 'nix-store --serve' protocol mismatch from 'songpola@10.0.1.101', got 'started
#        ��RT'
exec /mnt/c/Windows/System32/OpenSSH/ssh.exe "$@"
