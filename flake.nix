{
  description = "Alec's Nix system configurations";

  inputs = {
    # Nixpkgs - always pull from unstable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = { # Manage user home
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ags = { # Desktop shell
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, home-manager, nixpkgs, ... }: {
    nixosConfigurations = {
      # Laptop config
      "alecslaptop" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/alecslaptop/default.nix
          ./modules/desktop.nix
          home-manager.nixosModules.home-manager
        ];
      };
      
      # VM config
      "vm" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/vm/hardware-configuration.nix
          ./modules/desktop.nix
          home-manager.nixosModules.home-manager
        ];
      };

      # Desktop config TODO add me
      /*"alecspc" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        #extraSpecialArgs = { inherit inputs; }; # Should be put in hm config
        modules = [
          #./hosts/raspi/default.nix
          #./nixos/alecslaptop/common.nix
          #home-manager.nixosModules.home-manager
        ];
      };*/

      # Raspberry Pi
      /*"alecpi" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/raspi/default.nix
          ./hosts/common.nix
          home-manager.nixosModules.home-manager
        ];
      };*/
    };
  };
}
