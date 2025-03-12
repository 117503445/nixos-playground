{
  config,
  pkgs,
  ...
}: {
  home.username = "root";
  home.homeDirectory = "/root";

  imports = [
    ../apps/zsh/home.nix
  ];

  home.packages = with pkgs; [
    neofetch
    wget

    # archives
    zip
    xz
    unzip

    dig

    zsh
    micro

    python3
    go

    file
    which
    tree

    htop
    btop # replacement of htop/nmon
    iotop # io monitoring
    iftop # network monitoring

    zellij
    ncdu

    code-server
    cloc
    go-task
    yazi
  ];

  # git 相关配置
  programs.git = {
    enable = true;
    userName = "117503445";
    userEmail = "t117503445@gmail.com";
  };

  # 启用 starship，这是一个漂亮的 shell 提示符
  # programs.starship = {
  #   enable = true;
  #   # 自定义配置
  #   settings = {
  #     add_newline = false;
  #     aws.disabled = true;
  #     gcloud.disabled = true;
  #     line_break.disabled = true;
  #   };
  # };

  # programs.bash = {
  #   enable = true;
  #   enableCompletion = true;
  #   bashrcExtra = ''
  #     export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin"
  #   '';
  #   shellAliases = {
  #     k = "kubectl";
  #     urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
  #     urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";
  #   };
  # };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "24.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
