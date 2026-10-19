{
  description = "Haskell development flake for clover";

  inputs.nixpkgs.url = "nixpkgs/nixos-26.05";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      hp = pkgs.haskell.packages.ghc912;
    in {
      packages.default = hp.developPackage {
        root = ./.;
        withHoogle = true;
        returnShellEnv = true;

        # developPackage doesn't read cabal.project, so we need to manually pass
        # the dependencies specified there
        overrides = self: super: {
          SDL3 = pkgs.sdl3;
          SDL3_image = pkgs.sdl3-image;
          libmpdclient = pkgs.libmpdclient;
        };

        modifier = let
          addBuildTools = drv: pkgs.haskell.lib.addBuildTools drv [
            hp.cabal-install
            hp.haskell-language-server
            hp.hasktags # was getting messages that this was missing??
            pkgs.pkg-config
          ];
          addExtraLibraries = drv: pkgs.haskell.lib.addExtraLibraries drv [
            # Required dependencies for building sdl3 with `cabal build`
            pkgs.sdl3
            pkgs.alsa-lib
            pkgs.jack2.dev
            pkgs.pipewire.dev
            pkgs.libpulseaudio
            pkgs.libx11
            pkgs.libxcb
            pkgs.libXau
            pkgs.libXdmcp
            pkgs.libxext
            pkgs.libxcursor
            pkgs.libxrender
            pkgs.libXfixes
            pkgs.libxi
            pkgs.libxrandr
            pkgs.libxscrnsaver
            pkgs.libxtst
            pkgs.libdrm
            pkgs.libgbm
            pkgs.wayland.dev
            pkgs.libffi
            pkgs.libGL
            pkgs.libxkbcommon
            pkgs.libdecor
            pkgs.libusb1

            # Dependencies for SDL3_Image
            pkgs.sdl3-image

            # Dependencies for libmpdclient
            pkgs.libmpdclient
          ];
          in drv: addBuildTools (addExtraLibraries drv);
      };
    });
}
