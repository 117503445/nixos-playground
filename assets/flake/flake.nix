{
  description = "NixOS Playground";

  nixConfig = {
    require-sigs = false;
    post-build-hook = ./scripts/upload-to-cache.sh;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    impermanence.url = "github:nix-community/impermanence";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    buildImages = node: node.config.system.build.diskoImages;

    mkNixosConfig = name: let
      configPath = ./nodes/${name}/configuration.nix;
      homePath = ./nodes/${name}/home.nix;
    in
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          inputs.impermanence.nixosModules.impermanence
          inputs.disko.nixosModules.disko
          configPath
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.root = import homePath;
          }
        ];
      };

    nodes = [
      "nixos-test"
      "router-test"
      "guest-test"
    ];
  in {
    packages.x86_64-linux = builtins.listToAttrs (map (name: {
        name = "build-${name}";
        value = buildImages self.nixosConfigurations."${name}";
      })
      nodes);

    nixosConfigurations = builtins.listToAttrs (map (name: {
        name = name;
        value = mkNixosConfig name;
      })
      nodes);
  };
}
