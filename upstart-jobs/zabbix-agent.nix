{config, pkgs}:

let

  cfg = config.services.zabbixAgent;

  stateDir = "/var/run/zabbix";

  logDir = "/var/log/zabbix";

  pidFile = "${stateDir}/zabbix_agentd.pid";

  configFile = pkgs.writeText "zabbix_agentd.conf" ''
    Server = ${cfg.server}

    LogFile = ${logDir}/zabbix_agentd
  
    PidFile = ${pidFile}

    StartAgents = 5
  '';

in

{
  name = "zabbix-agent";
  
  users = [
    { name = "zabbix";
      uid = (import ../system/ids.nix).uids.zabbix;
      description = "Zabbix daemon user";
    }
  ];

  job = ''
    start on network-interfaces/started
    stop on network-interfaces/stop

    description "Zabbix agent daemon"

    start script
      mkdir -m 0755 -p ${stateDir} ${logDir}
      chown zabbix ${stateDir} ${logDir}
      
      export PATH=${pkgs.nettools}/bin:$PATH
      ${pkgs.zabbixAgent}/sbin/zabbix_agentd --config ${configFile}
    end script

    respawn sleep 100000
    
    stop script
      # !!! this seems to leave processes behind.
      #pid=$(cat ${pidFile})
      #if test -n "$pid"; then
      #  kill $pid 
      #fi

      # So instead kill the agent in a brutal fashion.
      while ${pkgs.procps}/bin/pkill -u zabbix zabbix_agentd; do true; done
    end script
  '';
  
}
