let inherit (import /etc/nixos/common.nix) hostname; in
{
  project.name = "zabbixproxy";
  services.zabbixproxy = {
    service.image = "zabbix/zabbix-proxy-sqlite3";
    service.user = "root";
    service.volumes = [ "${toString ./.}/docker/zabbix/proxy/db_data:/var/lib/zabbix/db_data/" ];
    service.environment.ZBX_SERVER_HOST = "XXXX;
    service.environment.ZBX_PROXYMODE = "0";
    service.environment.ZBX_HOSTNAME = "${hostname}";
  };
}
