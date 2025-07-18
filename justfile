set shell := ["nu", "-c"]

clean-channels:
	sudo rm -r /root/.nix-defexpr/channels
	sudo rm -r /nix/var/nix/profiles/per-user/root/channels
