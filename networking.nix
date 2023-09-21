{
  networking.hostName = "nixos-vm";

  networking.enableIPv6 = false;
  networking.networkmanager.enable = true;

  networking.firewall.enable = false;
  networking.firewall.allowedTCPPorts = [ 3389 ];
}
