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
    unzip
    wget
    arion
    docker-client
    git
  ];

  # Enable docker
  virtualisation.docker.enable = true;

  # Tell arion to use Docker
  virtualisation.arion.backend = "docker";

  # Define our Zabbix Proxy container
  virtualisation.arion.projects.zabbix.settings.services = {
        zabbixproxy.service = {
          image = "zabbix/zabbix-proxy-sqlite3:6.4.11-alpine";
          user = "root";
          ports = [            
            "10051:10051"
            "162:162"
                  ];
          volumes = [
            "/docker/zabbix/proxy/db_data:/var/lib/zabbix/db_data/"
            "/docker/nixos-public/zabbix/MIBs:/var/lib/zabbix/mibs/"
            "/docker/nixos-public/zabbix/snmptraps:/var/lib/zabbix/snmptraps/"
            "/docker/nixos-public/zabbix/modules:/var/lib/zabbix/modules/"
                    ];
          environment.ZBX_SERVER_HOST = "zabbix.monkey-duck.ts.net";
          environment.ZBX_PROXYMODE = "0";
          environment.ZBX_HOSTNAME = "${hostname}";
          environment.ZBX_ENABLE_SNMP_TRAPS = "true";
        };
  };

  # Define our Zabbix Agent container
   virtualisation.arion.projects.zabbix.settings.services = {
        zabbixagent.service = {
          image = "zabbix/zabbix-agent2:6.4.11-alpine";
          user = "root";
          ports = [
            "10050:10050"
                  ];
          volumes = [
            "/docker/zabbix/agent/:/var/lib/zabbix/agent/"
                    ];
          environment.ZBX_SERVER_HOST = "zabbix.monkey-duck.ts.net";
          environment.ZBX_HOSTNAME = "${hostname}";
          environment.ZBX_TLSCONNECT = "psk";
          environment.ZBX_TLSPSKFILE = "/var/lib/zabbix/agent/agentpsk.psk";
          environment.ZBX_TLSPSKIDENTITY = "4WSSPSK001";
        };
  };

  # Enable Tailscale
  services.tailscale.enable = true;
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
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
        if [ $status = "Running" ]; then #
          ${tailscale}/bin/tailscale up -authkey ${ts_key}
          exit 0
        fi
        ${tailscale}/bin/tailscale up -authkey ${ts_key}      
    '';
  };

  # Enable SSH.
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

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
