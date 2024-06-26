{ config, pkgs, ... }:

# Import variables from common.nix (generated using configure.sh)
let inherit (import /etc/nixos/common.nix) hostname username ts_key tsroute_enabled tssubnet; in

{
  imports =
    [
      # Include the hardware configuration for the machine.
      /etc/nixos/hardware-configuration.nix
      # Download arion and build from source
      ((builtins.fetchTarball "https://github.com/hercules-ci/arion/archive/f295eabd25b7c894ab405be784e2a010f83fde55.tar.gz") + "/nixos-module.nix")
    ];

  # systemd
  boot.loader.systemd-boot.enable = true;

  # Networking
  networking.hostName = "${hostname}";
  networking.useDHCP = true;
  time.timeZone = "Europe/London";

  # Install these packages
  environment.systemPackages = with pkgs; [
    tailscale
  ];

  # Enable Tailscale
  services.tailscale.enable = true;
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 1;
  networking.firewall.enable = false;
  networking.firewall.checkReversePath = "loose";

  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";
    after = [ "network-pre.target" "tailscale.service" ];
    wants = [ "network-pre.target" "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";

    script = with pkgs; ''
        sleep 2
          if [ $status = "Running" ]; then
            ${tailscale}/bin/tailscale up --authkey ${ts_key} --ssh --advertise-exit-node
            # tailscale set --auto-update
            exit 0
          fi
          ${tailscale}/bin/tailscale up --authkey ${ts_key} --ssh --advertise-exit-node
          # tailscale set --auto-update      
      '';
  };

  # Enable SSH.
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  # Proxmox Guest Tools
  services.qemuGuest.enable = true;

  # Sorandom
  system.stateVersion = "23.11";

  # Dont require password to sudo
  security.sudo.wheelNeedsPassword = false;

  # User information
  users.users = {
    "${username}" = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ];
      openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCtUnYdwOSLoMG5C+8XRuBp01Ll+dCtgh7rKD5k0W8L5FmLffQ2HPTFAMperOQY33NAqKMrmlX9o6YBnWCig6a81bRzwJ9suqb8hnrkdratTxQqSl9lOuPxP6XYOWF2mmoZg+CFuQrFMXnO9dokQpjDWNK2s+RYtGfoZaEdsoKb6MshmgQ0zEd4/LNz46b50e0jcwfKR7eCmgaatKB10Bp/CU2pzx/jg6Wriqs55Zpx9abcamIVwENBJjQrHyG9hL0wUctLzMR59F0h48IT0Ze87X27DxBhV8vQOWRSfrAYxh/6EgnN/u6HHEN3vb/IneVoHxSMsnaI/QWh7NOeZBTR rsa-key-20230110" ];
    };
  };
}
