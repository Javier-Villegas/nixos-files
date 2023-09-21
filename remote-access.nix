{ lib, config, ...}:
{
  imports = [
    ./xrdp-custom.nix
  ];
  
  services.openssh.enable = true;

  services.xrdp= {
    enable = true;
    defaultWindowManager = "startplasma-x11";
    openFirewall = true;
  };

  #systemd.services.xrdp-sesman.serviceConfig.ExecStart = lib.mkForce "${config.services.xrdp.package}/bin/xrdp-sesman --nodaemon --config ${config.services.xrdp.confDir}/etc/xrdp/sesman.ini}";
}
