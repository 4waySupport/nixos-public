{ config, pkgs, ... }:

{
      imports =
      [
        (builtins.fetchurl "https://raw.githubusercontent.com/4waySupport/nixos-public/main/zabbix/configuration.nix")
      ];
}
