{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.astal.follows = "astal";
    };
    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # TODO Remove
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    lightbrowse = {
      url = "github:AmazinAxel/lightbrowse";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    homelab = {
      url = "github:AmazinAxel/homelab";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    printerblot = {
      url = "github:AmazinAxel/printerblot";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helix = {
      url = "github:helix-editor/helix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lookout-nix = {
      url = "github:cloudglides/lookout-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { home-manager, nixpkgs, homelab, printerblot, ... }@inputs: {
    nixosConfigurations = {

      # Primary laptop
      "alecslaptop" = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/alecslaptop/default.nix
          home-manager.nixosModules.home-manager
        ];
      };

      # Old laptop
      "alecolaptop" = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/alecolaptop/default.nix
          home-manager.nixosModules.home-manager
        ];
      };

      # Desktop/compute server
      "alecpc" = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/alecpc/default.nix
          home-manager.nixosModules.home-manager
        ];
      };

      # headless devices, build using
      # nixos-rebuild switch --flake .#<hostname> --sudo --ask-sudo-password --target-host alec@<hostname>.local

      # Homelab (Zero 2W)
      "alechomelab" = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/alechomelab/default.nix
          {
            _module.args.homelabDisplay = homelab.packages.aarch64-linux.homelabDisplay;
          }
        ];
      };

      # Localhost development server (Pi 4B)
      "alecdev" = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/alecdev/default.nix
          home-manager.nixosModules.home-manager
        ];
      };

      # VPS
      "alecvps" = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/alecvps/default.nix
        ];
      };

      # Permablot (custom printerblot printer, Zero 2W)
      "permablot" = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/permablot/default.nix
          {
            _module.args.printerblot = printerblot.packages.aarch64-linux;
          }
        ];
      };

      # Gaming handheld (aarch64)
      "alechandheld" = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/alechandheld/default.nix
          home-manager.nixosModules.home-manager
        ];
      };
    };
  };
}
