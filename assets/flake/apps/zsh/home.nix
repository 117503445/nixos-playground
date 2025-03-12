{
  config,
  pkgs,
  nixpkgs,
  ...
}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      # ll = "ls -l";
      dcu = "docker compose up -d";
      dcd = "docker compose down";
      dcr = "docker compose restart";
      dcl = "docker compose logs -f";
      dcp = "docker compose pull";
      dc-update = "docker compose pull && docker compose up -d";
    };
    history.size = 10000;
  };
}
