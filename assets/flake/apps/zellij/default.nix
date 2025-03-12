{
  config,
  pkgs,
  nixpkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [zellij];
}
