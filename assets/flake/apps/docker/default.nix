{
  config,
  pkgs,
  nixpkgs,
  ...
}: {
  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "btrfs";
  virtualisation.docker.daemon.settings = {
    data-root = "/workspace/docker-daemon";
  };
}
