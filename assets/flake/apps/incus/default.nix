{
  config,
  pkgs,
  nixpkgs,
  ...
}: {
  virtualisation.incus.enable = true;
  networking.nftables.enable = true;
  networking.firewall.trustedInterfaces = ["incusbr0"];
}
