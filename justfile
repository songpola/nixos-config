set shell := ["nu", "-c"]

prts-sw:
  nh os switch . -H prts --build-host prts --target-host prts -v

clean-channels:
	sudo rm -r /root/.nix-defexpr/channels
	sudo rm -r /nix/var/nix/profiles/per-user/root/channels

add-podman-connections: add-podman-connections-wsl add-podman-connections-desktop allow-ssh-to-wsl-firewall

# Add remote connections: NixOS-WSL -> Podman Desktop
add-podman-connections-wsl:
	podman system connection add --default podman-machine-default unix:///mnt/wsl/podman-sockets/podman-machine-default/podman-user.sock
	podman system connection add podman-machine-default-root unix:///mnt/wsl/podman-sockets/podman-machine-default/podman-root.sock

# Add remote connections: Podman Desktop -> NixOS-WSL
add-podman-connections-desktop:
	podman.exe system connection add --identity 'C:\Users\songpola\.ssh\podman-desktop-nixos-wsl' --port 2222 nixos-wsl songpola@localhost
	podman.exe system connection default nixos-wsl

allow-ssh-to-wsl-firewall:
	sudo.exe pwsh.exe -c 'New-NetFirewallHyperVRule -Name "Allow-SSH-To-WSL-From-Localhost" -DisplayName "Allow SSH to WSL from localhost" -VMCreatorId "{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}" -Protocol TCP -LocalPorts 2222 -RemoteAddresses "127.0.0.1"'
