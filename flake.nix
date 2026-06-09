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
      sdl3 = hp.callCabal2nix
        "sdl3"
        (pkgs.fetchFromGitHub {
          owner = "breitnw";
          repo = "sdl3-hs";
          rev = "eacde89316d1112e4d737833d4dbf02142490ada";
          sha256 = "sha256-Ig1Tx3ccc4NOa3hKkQ5lx/3hnvAM4o34cE95DYalmlk=";
        })
        { SDL3 = pkgs-unstable.sdl3.dev; };
      libmpd = hp.callCabal2nix
        "libmpd"
        (pkgs.fetchFromGitHub {
          owner = "breitnw";
          repo = "libmpd-haskell";
          rev = "9e2bcccf8a9c3b2bdcff9ae466e69715a5b05544";
          sha256 = "sha256-TuaS5coVhsnCjlH1AGDHDA4JOBWa9DWDJA+/2d+3mBo=";
        })
        {};
    in {
      packages.default = hp.developPackage {
        root = ./.;
        withHoogle = true;
        # I believe these are needed to make HLS happy, but not sure
        # Both are needed for `nix run`
        overrides = self: super: { inherit sdl3 libmpd; };

        modifier = drv: pkgs.haskell.lib.addBuildTools drv [
          hp.cabal-install
          hp.haskell-language-server

          # TODO why doesn't withHoogle provide this??
          (hp.hoogleWithPackages (p: [
            sdl3
            libmpd
            p.stb-image
            p.mtl
            p.bytestring
            p.containers
          ]))

          # not required to build (since we override sdl3), but needed for
          # haskell-language-server (or cabal build) to work properly
          pkgs-unstable.sdl3
        ];
      };
    });
}
