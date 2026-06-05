{
  description = "Haskell development flake for clover";

  inputs.nixpkgs.url = "nixpkgs/nixos-25.11";
  inputs.nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = {
    nixpkgs,
    nixpkgs-unstable,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
      hp = pkgs.haskell.packages.ghc96;
    in {
      packages.default = hp.developPackage {
        root = ./.;
        withHoogle = true;
        overrides = self: super: {
          sdl3 = hp.callCabal2nix
            "sdl3"
            (pkgs.fetchFromGitHub {
              owner = "breitnw";
              repo = "sdl3-hs";
              rev = "eacde89316d1112e4d737833d4dbf02142490ada";
              sha256 = "sha256-Ig1Tx3ccc4NOa3hKkQ5lx/3hnvAM4o34cE95DYalmlk=";
            })
            { SDL3 = pkgs-unstable.sdl3.dev; };
        };
        modifier = drv: pkgs.haskell.lib.addBuildTools drv [
          hp.cabal-install
          hp.haskell-language-server

          # not required to build (since we override sdl3), but needed for
          # haskell-language-server (or cabal build) to work properly
          pkgs-unstable.sdl3
        ];
      };
    });
}
