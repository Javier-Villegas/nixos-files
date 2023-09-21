{ pkgs, ... }:
{
  users.users.syoru.packages = with pkgs; [
    librewolf
    tree
    discord
    neofetch
  ];
}
