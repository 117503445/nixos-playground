{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: {
  # 开启 SSH 服务端，监听 22 端口
  services.openssh = {
    enable = true;
    ports = [22];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = lib.mkForce "prohibit-password";
    };
  };
}
