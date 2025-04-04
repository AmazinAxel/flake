{
  description = "Alec's Nix system configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { home-manager, nixpkgs, ... }: {
    nixosConfigurations = {
      # Laptop config
      "alecslaptop" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/alecslaptop/default.nix
          home-manager.nixosModules.home-manager
        ];
      };

      # Desktop config
      "alecpc" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/alecpc/default.nix
          home-manager.nixosModules.home-manager
        ];
      };

      # Old laptop config
      "alecolaptop" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/alecolaptop/default.nix
          home-manager.nixosModules.home-manager
        ];
      };

      # Raspberry Pi
      "alecpi" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/alecpi/default.nix
          home-manager.nixosModules.home-manager
        ];
      };
    };
  };
}
