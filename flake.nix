{
  description = "Alec's Nix config";

  inputs = {
    # Nixpkgs - always pull from unstable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

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
          ./modules/hyprland.nix
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
