{
  description = "Alec's Nix config";

  inputs = {
    # Nixpkgs - always pull from unstable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Widget system - Ags v2
    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Manages home configs
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    home-manager,
    nixpkgs,
    ...
  }: {

    nixosConfigurations = {
      # Laptop config
      "alecslaptop" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/alecslaptop/default.nix
          ./hosts/common.nix
          ./modules/desktop.nix
          home-manager.nixosModules.home-manager {
            home-manager = {
              backupFileExtension = "backup";
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs; };
              users.alec = {
                home.username = "alec";
                home.homeDirectory = "/home/alec";
                imports = [ ./home-manager/home.nix ];
              };
            };
          }
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

      # VM config
      "vm" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/vm/hardware-configuration.nix
          ./hosts/common.nix
          ./modules/desktop.nix
          home-manager.nixosModules.home-manager {
            home-manager = {
              backupFileExtension = "backup";
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs; };
              users.alec = {
                home.username = "alec";
                home.homeDirectory = "/home/alec";
                imports = [ ./home-manager/home.nix ];
              };
            };
          }
        ];
      };

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
