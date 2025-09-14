{
  description = "Modular NixOS configuration with flakes and Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";

    hyprland = {
      url = "github:hyprwm/hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    flake-utils,
    hyprland,
    ...
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      packages.default = pkgs.hello;
      devShells.default = pkgs.mkShell {
        name = "media-tools";
        packages = with pkgs; [
          ffmpeg
          mediainfo
          jq
          bashInteractive
        ];
        shellHook = ''
          echo "Media tools shell: ffmpeg $(ffmpeg -version | head -n1)" || true
        '';
      };
    })
    // {
      nixosConfigurations = {
        asus = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/asus.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {inherit inputs;};
              home-manager.users.cloudgenius = import ./home/cloudgenius.nix;
            }
          ];
          specialArgs = {
            inherit hyprland;
          };
        };
        venus = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/venus.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {inherit inputs;};
              home-manager.users.cloudgenius = import ./home/cloudgenius.nix;
            }
          ];
          specialArgs = {
            inherit hyprland;
          };
        };
      };
    };
}
