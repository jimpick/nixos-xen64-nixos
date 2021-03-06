let

  fromEnv = name: default:
    let env = builtins.getEnv name; in
    if env == "" then default else env;
  configuration = import (fromEnv "NIXOS_CONFIG" /etc/nixos/configuration.nix);
  nixpkgsPath   =         fromEnv "NIXPKGS"      /etc/nixos/nixpkgs;

  system = import system/system.nix { inherit configuration nixpkgsPath; };

in

{ inherit (system)
    activateConfiguration
    bootStage2
    etc
    grubMenuBuilder
    kernel
    modulesTree
    nix
    system
    systemPath
    config
    ;

  inherit (system.nixosTools)
    nixosCheckout
    nixosHardwareScan
    nixosInstall
    nixosRebuild
    nixosGenSeccureKeys
    ;

  inherit (system.initialRamdiskStuff)
    bootStage1
    extraUtils
    initialRamdisk
    modulesClosure
    ;
    
  nixFallback = system.nix;

  manifests = system.config.installer.manifests; # exported here because nixos-rebuild uses it

  upstartJobsCombined = system.upstartJobs;

  # Make it easier to build individual Upstart jobs (e.g., "nix-build
  # /etc/nixos/nixos -A upstartJobs.xserver").  
  upstartJobs = { recurseForDerivations = true; } //
    builtins.listToAttrs (map (job:
      { name = if job ? jobName then job.jobName else job.name; value = job; }
    ) system.upstartJobs.jobs);

}
