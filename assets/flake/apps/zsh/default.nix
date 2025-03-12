{
  config,
  pkgs,
  nixpkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [zsh];

  users.users.root.shell = pkgs.zsh;
  programs.zsh = {
    enable = true;
    # autosuggestion.enable = true;

    shellAliases = {ll = "ls -l";};
    # history = { size = 10000; };
    ohMyZsh = {
      enable = true;
      plugins = ["git"];
      theme = "eastwood";
    };
  };
}
