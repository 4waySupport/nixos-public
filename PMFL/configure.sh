#!/bin/sh

nix_config_url="https://raw.githubusercontent.com/4waySupport/nixos-public/main/PMFL/localconfiguration.nix"

# read -p "Username: " username
read -p "Hostname: " hostname
read -p "Tailscale Key: " tskey

# Download live config
curl $nix_config_url > /etc/nixos/configuration.nix

# Build local configuration

cat <<EOF > /etc/nixos/common.nix
{
  hostname = "$hostname";
  username = "fourway";
  ts_key = "$tskey";
  tsroute_enabled = "$tsroute_enabled";  
}
EOF
