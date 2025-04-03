let  ip = "192.168.146.128"
ssh-keygen -R $ip
SSHPASS=2545 (
    just
    generateHardwareConfig="nixos-facter"
    i
    nixos-vmw
    $"root@($ip)"
)
