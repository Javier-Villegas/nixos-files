{ pkgs, ... }:
{
  users.users.syoru = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
      "libvirtd"
    ];
    shell = pkgs.zsh;
  };
}
