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
          rev = "missing-video-exports";
          sha256 = "sha256-Ig1Tx3ccc4NOa3hKkQ5lx/3hnvAM4o34cE95DYalmlk=";
        })
        { SDL3 = pkgs-unstable.sdl3.dev; };
      libmpd = hp.callCabal2nix
        "libmpd"
        (pkgs.fetchFromGitHub {
          owner = "breitnw";
          repo = "libmpd-haskell";
          rev = "breitnw-dev";
          sha256 = "sha256-NLo1G9jsm60TAQyb6S6/JnXP47LIZOo2JAG8qjdFZ1U=";
        })
        {};
      libmpd-effectful = hp.callCabal2nix
        "libmpd"
        (pkgs.fetchFromGitHub {
          owner = "breitnw";
          repo = "libmpd-effectful";
          rev = "breitnw-dev";
          sha256 = "sha256-vKY43A2N0B8GL9nK0zzxeH9fX9LyKjU3LVVroLoqf4w=";
        })
        { inherit libmpd; };
    in {
      packages.default = hp.developPackage {
        root = ./.;
        withHoogle = true;
        returnShellEnv = true;

        # developPackage doesn't read cabal.project, so we need to manually pass
        # the dependencies specified there
        overrides = self: super: {
          inherit sdl3 libmpd-effectful;
        };

        modifier = drv: pkgs.haskell.lib.addBuildTools drv [
          hp.cabal-install
          hp.haskell-language-server

          # not required to `nix build` (since we override sdl3), but needed for
          # haskell-language-server (or cabal build) to work properly
          pkgs-unstable.sdl3
        ];
      };
    });
}
