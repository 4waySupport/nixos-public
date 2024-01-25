#!/bin/sh

nix_config_url="https://raw.githubusercontent.com/4waySupport/nixos-public/main/zabbix/localconfiguration.nix"
config_script="https://raw.githubusercontent.com/4waySupport/nixos-public/main/zabbix/configure.sh"

# Create partitions
parted --script /dev/sda -- mklabel gpt
parted --script  /dev/sda -- mkpart primary 512MiB -8GiB
parted --script  /dev/sda -- mkpart primary linux-swap -8GiB 100%
parted --script  /dev/sda -- mkpart ESP fat32 1MiB 512MiB
parted --script  /dev/sda -- set 3 esp on

# Format partitions
mkfs.ext4 -L NIXOS /dev/sda1
mkswap -L swap /dev/sda2
mkfs.fat -F 32 -n BOOT /dev/sda3

# Mount
mount /dev/disk/by-label/NIXOS /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/BOOT /mnt/boot
swapon /dev/sda2

# Generate hardware config
nixos-generate-config --root /mnt

# Enable SSH and allow root login
sed -i 's/  \# services.openssh.enable = true\;/  services.openssh.enable = true\; \
  services.openssh.settings.PermitRootLogin = \"yes\"\; /g' /mnt/etc/nixos/configuration.nix

# Install - Do not prompt for root password.
nixos-install  --no-root-passwd

# Download configure script
mkdir -p /mnt/root
curl $config_script > /mnt/root/configure.sh
chmod +x /mnt/root/configure.sh

echo "Please reboot"
