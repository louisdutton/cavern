{
  description = "A Nix-flake-based Odin development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];

    forEachSupportedSystem = f:
      nixpkgs.lib.genAttrs supportedSystems (
        system:
          f {
            pkgs = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
          }
      );
  in {
    packages = forEachSupportedSystem (
      {pkgs}:
        with pkgs; {
          default = stdenv.mkDerivation {
            pname = "cavern";
            version = "0.1.0";
            src = ./.;

            nativeBuildInputs = [
              odin
              raylib
              makeBinaryWrapper
            ];

            buildPhase = ''
              odin build . -o:speed
            '';

            installPhase = ''
              mkdir -p $out/bin $out/share/cavern
              cp cavern.bin $out/bin/cavern
              cp -r res/* $out/share/
              wrapProgram $out/bin/cavern \
                --set-default RES_ROOT $out/share
            '';
          };
        }
    );

    devShells = forEachSupportedSystem (
      {pkgs}:
        with pkgs; {
          default = mkShell {
            nativeBuildInputs = [
              odin
              raylib
            ];

            packages = [
              # tools
              claude-code
              # aseprite

              # debugging
              gdb

              # language support
              ols
              nixd
              alejandra
            ];

            # GALLIUM_HUD = "fps,cpu";
            XDG_SESSION_TYPE = "x11"; # wayland can't handle fullscreen
            RES_ROOT = "./res";
          };
        }
    );
  };
}
