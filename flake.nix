{
  description = "CLI tool to make a PDF of a raw text file";

  inputs.pins.url                 = "github:anderslundstedt/nix-pins";
  inputs.nixpkgs-unstable.follows = "pins/nixpkgs-unstable";
  inputs.flake-utils.follows      = "pins/flake-utils";

  inputs.check-unicode-coverage.url =
    "github:anderslundstedt/check-unicode-coverage";
  inputs.check-unicode-coverage.inputs.pins.follows = "pins";

  inputs.iosevka-custom-fixed-slab-extra-extended.url =
    "github:anderslundstedt/iosevka-custom-fixed-slab-extra-extended";
  inputs.iosevka-custom-fixed-slab-extra-extended.inputs.pins.follows = "pins";

  outputs = inputs@{self,...}:
    let
      # to work with older version of flakes
      lastModifiedDate =
        self.lastModifiedDate or self.lastModified or "19700101";

      # generate a user-friendly version number.
      version = builtins.substring 0 8 lastModifiedDate;

      # confirmed to work on the following systems
      systems-linux    = ["x86_64-linux"  "aarch64-linux"];
      systems-darwin   = ["aarch64-darwin"];
      supportedSystems = systems-linux ++ systems-darwin;
    in
      inputs.flake-utils.lib.eachSystem supportedSystems (system:
        let
          nixpkgs-unstable           =
            inputs.nixpkgs-unstable.legacyPackages.${system};
          pkg-check-unicode-coverage =
            inputs.check-unicode-coverage.packages.${system}.default;
          pkg-iosevka                =
            inputs.iosevka-custom-fixed-slab-extra-extended.packages.${system}.default;
          get-python-env   = is-dev-shell: (
            nixpkgs-unstable.python312.withPackages (python-packages:
              builtins.filter(x: x != 0) [
                (if is-dev-shell then python-packages.ipython else 0)
                python-packages.python-fontconfig
              ]
            )
          );
        in {
          devShells.default = nixpkgs-unstable.mkShell {
            buildInputs = [
              pkg-check-unicode-coverage
              nixpkgs-unstable.coreutils
              nixpkgs-unstable.gh
              nixpkgs-unstable.gh-markdown-preview
              nixpkgs-unstable.texliveSmall
              (get-python-env true)
            ];
            shellHook = ''
              cp ${nixpkgs-unstable.cm_unicode}/share/fonts/opentype/cmuntt.otf          .
              cp ${nixpkgs-unstable.julia-mono}/share/fonts/truetype/JuliaMono-Light.ttf .
              cp \
                ${pkg-iosevka}/share/fonts/truetype/IosevkaCustom-Fixed-Slab-ExtraExtended-Regular.ttf \
                .
              chmod -x IosevkaCustom-Fixed-Slab-ExtraExtended-Regular.ttf
            '';
          };

          packages.default = nixpkgs-unstable.stdenv.mkDerivation {
            name = "txt2pdf-${version}";

            buildInputs = [
              nixpkgs-unstable.makeWrapper
            ];

            unpackPhase = "true";

            installPhase = ''
              mkdir -p $out/bin
              cp ${./txt2pdf.py}                                              $out/txt2pdf
              cp ${./template.tex}                                            $out/template.tex
              cp ${nixpkgs-unstable.cm_unicode}/share/fonts/opentype/cmuntt.otf           $out/cmuntt.otf
              cp ${nixpkgs-unstable.julia-mono}/share/fonts/truetype/JuliaMono-Light.ttf  $out/JuliaMono-Light.ttf
              cp \
                ${pkg-iosevka}/share/fonts/truetype/IosevkaCustom-Fixed-Slab-ExtraExtended-Regular.ttf \
                $out/IosevkaCustom-Fixed-Slab-ExtraExtended-Regular.ttf
              chmod -x $out/IosevkaCustom-Fixed-Slab-ExtraExtended-Regular.ttf
              makeWrapper \
                $out/txt2pdf \
                $out/bin/txt2pdf \
                --set PATH ${nixpkgs-unstable.lib.makeBinPath [
                  pkg-check-unicode-coverage
                  nixpkgs-unstable.coreutils
                  nixpkgs-unstable.texliveSmall
                  (get-python-env false)
                ]}
            '';
          };
        }
      );
}
