{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../../lib/home.nix
  ];
  # home.packages = with pkgs; [
  #   tailscale
  # ];
}
