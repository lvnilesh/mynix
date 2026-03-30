{
  description = "Modular NixOS configuration with flakes and Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    hyprland = {
      url = "github:hyprwm/hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    hyprland,
    hermes-agent,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    devShells.${system}.default = pkgs.mkShell {
      name = "media-tools";
      packages = with pkgs; [
        ffmpeg
        mediainfo
        jq
        bashInteractive
        tcpdump
        websocat
      ];
      shellHook = ''
        echo "Media tools shell: ffmpeg $(ffmpeg -version | head -n1)" || true
      '';
    };

    nixosConfigurations = {
      asus = nixpkgs.lib.nixosSystem {
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
          inherit hyprland inputs;
        };
      };
      venus = nixpkgs.lib.nixosSystem {
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
      nuc = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/nuc.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit inputs;};
            home-manager.users.cloudgenius = import ./home/headless.nix;
          }
        ];
      };
    };
  };
}
