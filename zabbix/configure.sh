#!/bin/sh

nix_config_url="https://raw.githubusercontent.com/4waySupport/nixos-public/main/zabbix/localconfiguration.nix"

# read -p "Username: " username
read -p "Hostname: " hostname
read -p "Tailscale Key: " tskey
read -p "Agent registration PSK: " agentpsk
read -p "Agent registration Identity: " agentid

# Download live config
curl $nix_config_url > /etc/nixos/configuration.nix

# Build local configuration

echo $agentpsk > /docker/zabbix/agent/agentpsk
echo $agentid > /docker/zabbix/agent/agentid

cat <<EOF > /etc/nixos/common.nix
{
  hostname = "$hostname";
  username = "fourway";
  ts_key = "$tskey";
  tsroute_enabled = "$tsroute_enabled";  
}
EOF
