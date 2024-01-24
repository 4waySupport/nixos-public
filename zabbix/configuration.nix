{ config, pkgs, ... }:

# Import variables from common.nix (generated using configure.sh)
let inherit (import /etc/nixos/common.nix) hostname username ts_key tsroute_enabled tssubnet; in

{
  imports =
    [
      # Include the hardware configuration for the machine.
      /etc/nixos/hardware-configuration.nix
      ((builtins.fetchTarball "https://github.com/hercules-ci/arion/archive/f295eabd25b7c894ab405be784e2a010f83fde55.tar.gz") + "/nixos-module.nix")
    ];

#  imports =
#    [
#       ((builtins.fetchTarball "https://github.com/hercules-ci/arion/archive/f295eabd25b7c894ab405be784e2a010f83fde55.tar.gz") + "/nixos-module.nix")
#    ];

  # systemd
  boot.loader.systemd-boot.enable = true;

  # Networking
  networking.hostName = "${hostname}";
  networking.useDHCP = true;
  time.timeZone = "Europe/London";

  environment.systemPackages = with pkgs; [
    tailscale
    unzip
    wget
    pwgen
    arion
    docker-client
  ];

#  This below commented out config is easy, but it uses an outdated version of Zabbix Proxy, so instead a container was used. This config might become relevant in the future, so it has been left here.

#  services.zabbixProxy = {
#    enable = true;
#    server = "dajeubntzabbix.tailadc66.ts.net"; # Change this to your Zabbix server's hostname or IP address
#    database.type = "sqlite";
#    database.name = "/var/lib/zabbix/db.db";
#    database.createLocally = false;
#    database.user = "zabbix";
#  };

  virtualisation.docker.enable = true;
#  virtualisation.podman.enable = false;
#  virtualisation.podman.dockerSocket.enable = true;
#  virtualisation.podman.defaultNetwork.settings.dns_enabled = true;

# Declare environment variable for the build part for Arion

# env = {
#  DOCKER_HOST = "unix:///run/podman/podman.sock";
# };



#  This below commented out confis is trying to get the container to run from the main nix config, and avoid requiring arion-compose.nix and having to run arion up. The config on line 11 is also trying to get this working.

  virtualisation.arion = {
    backend = "docker";
    projects.zabbixproxy = {
      serviceName = "zabbixproxy";
      settings = {
        project.name = "zabbixproxy";
        services.zabbixproxy = {
          service.image = "zabbix/zabbix-proxy-sqlite3";
          service.user = "root";
          service.volumes = [ "${toString ./.}/docker/zabbix/proxy/db_data:/var/lib/zabbix/db_data/" ];
          service.environment.ZBX_SERVER_HOST = "dajeubntzabbix.tailadc66.ts.net";
          service.environment.ZBX_PROXYMODE = "0";
          service.environment.ZBX_HOSTNAME = "${hostname}";
        };
      };
    };
  };

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
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ ${tsroute_enabled} = "y" ]; then # if tailscale routing is enabled.
        if [ $status = "Running" ]; then
          ${tailscale}/bin/tailscale up -authkey ${ts_key} --advertise-routes ${tssubnet}
          exit 0
        fi
        ${tailscale}/bin/tailscale up -authkey ${ts_key} --advertise-routes ${tssubnet}
      else # if tailscale routing is not enabled
        if [ $status = "Running" ]; then #
          ${tailscale}/bin/tailscale up -authkey ${ts_key}
          exit 0
        fi
        ${tailscale}/bin/tailscale up -authkey ${ts_key}
      fi

    '';
  };

  # Enable SSH.
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  # Sorandom
  system.stateVersion = "23.11";

#  # Export DOCKER_HOST variable so that it uses podman instead of docker
#  environment.variables.DOCKER_HOST = "unix:///run/podman/podman.sock";

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
