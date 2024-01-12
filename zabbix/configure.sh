#!/bin/sh

nix_config_url="https://raw.githubusercontent.com/4waySupport/nixos-public/main/vPentest/localconfiguration.nix"

read -p "Username: " username
read -p "Hostname: " hostname
read -p "Tailscale Key: " tskey
read -p "Do you want to expose a Tailscale Route? [y/n]: " tsroute_enabled
if [ $tsroute_enabled = y ]
then
  read -p "Tailscale route: " tssubnet
fi

# Download live config
curl $nix_config_url > /etc/nixos/configuration.nix

# Build local configuration
cat <<EOF > /etc/nixos/common.nix
{
  hostname = "$hostname";
  username = "$username";
  ts_key = "$tskey";
  tsroute_enabled = "$tsroute_enabled";
  tssubnet = "$tssubnet";
}
EOF
