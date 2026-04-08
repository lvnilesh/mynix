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

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    hyprland,
    hermes-agent,
    agenix,
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
        python3Packages.pikepdf

        # Document processing tools (added April 2026)
        poppler-utils # pdftoppm, pdfunite, pdftotext
        qpdf # PDF inspection
        ghostscript # PDF conversion
        tesseract # OCR
        imagemagick # Image/PDF manipulation
        python313Packages.pillow # PIL for image manipulation
        python313Packages.reportlab # PDF generation
        dejavu_fonts # Fonts for PIL/ReportLab
      ];
      shellHook = ''
        echo "Media and document tools shell"
        echo "  ffmpeg $(ffmpeg -version 2>&1 | head -n1)"
        echo "  tesseract $(tesseract --version 2>&1 | head -n1)"
        echo "  poppler-utils (pdftoppm, pdfunite) available"
        echo "  imagemagick (magick, convert) available"
      '';
    };

    nixosConfigurations = {
      asus = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/asus.nix
          home-manager.nixosModules.home-manager
          agenix.nixosModules.default
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit inputs;};
            home-manager.users.cloudgenius = import ./home/cloudgenius.nix;
          }
        ];
        specialArgs = {
          inherit hyprland agenix inputs;
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
