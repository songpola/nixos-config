set shell := ["nu", "-c"]

clean-channels:
	sudo rm -r /root/.nix-defexpr/channels
	sudo rm -r /nix/var/nix/profiles/per-user/root/channels

add-podman-desktop-connections:
	podman system connection add --default podman-machine-default unix:///mnt/wsl/podman-sockets/podman-machine-default/podman-user.sock
	podman system connection add podman-machine-default-root unix:///mnt/wsl/podman-sockets/podman-machine-default/podman-root.sock
