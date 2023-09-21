{ pkgs, ...}:

{
  nixpkgs.config.allowUnfree = true;
  # List of packages installed in system profile
  environment.systemPackages = with pkgs; [
    neovim
    wget
    git
    kitty
    thunderbird
    virt-manager
  ];
}
