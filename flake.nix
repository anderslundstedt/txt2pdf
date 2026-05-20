# flake based on
# https://github.com/NixOS/templates/blob/ad0e221dda33c4b564fad976281130ce34a20cb9/bash-hello/flake.nix
{
  description = "CLI tool to make a PDF of a raw text file";

  inputs.nixpkgs.url                = "nixpkgs/nixpkgs-unstable";
  inputs.nixpkgs-24-11-darwin.url   = "nixpkgs/nixpkgs-24.11-darwin";

  inputs.check-unicode-coverage = {
    url    = "github:anderslundstedt/check-unicode-coverage";
    inputs = {
      nixpkgs.follows              = "nixpkgs";
      nixpkgs-24-11-darwin.follows = "nixpkgs-24-11-darwin";
      nixpkgs-24-11-linux.follows  = "nixpkgs";
    };
  };

  outputs = {self, check-unicode-coverage, nixpkgs, ...}: (
    let
      # to work with older version of flakes
      lastModifiedDate =
        self.lastModifiedDate or self.lastModified or "19700101";

      # generate a user-friendly version number.
      version = builtins.substring 0 8 lastModifiedDate;

      # confirmed to work on the following systems
      systems-linux    = ["x86_64-linux"  "aarch64-linux"];
      systems-darwin   = ["x86_64-darwin" "aarch64-darwin"];
      supportedSystems = systems-linux ++ systems-darwin;

      # helper function to generate an attrset
      # '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      get-python-env = pkgs: is-dev-shell: (
        pkgs.python313.withPackages (
          python-pkgs: (
            builtins.filter(x: x != 0) [
              (if is-dev-shell then python-pkgs.ipython else 0)
              (if is-dev-shell then python-pkgs.pyright else 0)
            ]
          )
        )
      );

      get-check-unicode-coverage =
        system: check-unicode-coverage.defaultPackage.${system};
    in {
      devShell = forAllSystems(system:
        let
          pkgs                   = nixpkgs.legacyPackages.${system};
        in (
          pkgs.mkShell {
            buildInputs = [
              (get-check-unicode-coverage system)
              (get-python-env pkgs false)
              pkgs.coreutils
              pkgs.texliveSmall
            ];
            shellHook = ''
              cp ${pkgs.cm_unicode}/share/fonts/opentype/cmuntt.otf          .
              cp ${pkgs.julia-mono}/share/fonts/truetype/JuliaMono-Light.ttf .
            '';
          }
        )
      );

      defaultPackage = forAllSystems(system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in (
          pkgs.stdenv.mkDerivation {
            name = "txt2pdf-${version}";

            buildInputs = [
              pkgs.makeWrapper
            ];

            unpackPhase = "true";

            installPhase = ''
              mkdir -p $out/bin
              cp ${./txt2pdf.py}                                             $out/txt2pdf
              cp ${pkgs.cm_unicode}/share/fonts/opentype/cmuntt.otf          $out/cmuntt.otf
              cp ${pkgs.julia-mono}/share/fonts/truetype/JuliaMono-Light.ttf $out/JuliaMono-Light.ttf
              cp ${./template.tex}                                           $out/template.tex
              makeWrapper \
                $out/txt2pdf \
                $out/bin/txt2pdf \
                --set PATH ${nixpkgs.lib.makeBinPath [
                  (get-check-unicode-coverage system)
                  pkgs.coreutils
                  pkgs.texliveSmall
                  (get-python-env pkgs false)
                ]}
            '';
          }
        )
      );
    }
  );
}
