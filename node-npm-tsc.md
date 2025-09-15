nix profile install nixpkgs#nodejs
nix profile install nixpkgs#nodePackages.typescript
# verify
~/.nix-profile/bin/tsc -v
# or
tsc -v

