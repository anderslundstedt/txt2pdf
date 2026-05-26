Pull requests updating this README are very welcome!

- With a flake-enabled¹ install of the [Nix package manager](https://nixos.org):

  ```
  nix run github:anderslundstedt/txt2pdf.github -- args
  ```

  Example run:

  ```
  $ nix run github:anderslundstedt/txt2pdf -- -h
    usage: txt2pdf [-h] [--font FONT | --Iosevka | --JuliaMono] [--author AUTHOR |
                   --no-author] [--text-width TEXT_WIDTH] [--allow-line-overflow]
                   [--no-filename-in-header] [--no-datetime-in-header]
                   [--no-author-in-header] [--no-header] [--no-page-numbers]
                   [--title-page] [--do-not-remove-tmp-files]
                   input

    Convert Unicode to pdf.

    positional arguments:
      input                 Input file.

    options:
      -h, --help            show this help message and exit
      --font FONT           path to font file (default:
                            /nix/store/11swawrhdii0611dpfgkjkyfkcgd9yih-
                            txt2pdf-20260526/cmuntt.otf)
      --Iosevka             Use font Iosevka (custom built extra extended slab
                            variant). (default: False)
      --JuliaMono           Use font JuliaMono. (default: False)
      --author AUTHOR       author (default: Anders E.V. Lundstedt)
      --no-author
      --text-width TEXT_WIDTH
                            number of characters per line (default: 70)
      --allow-line-overflow
      --no-filename-in-header
      --no-datetime-in-header
      --no-author-in-header
      --no-header
      --no-page-numbers
      --title-page          Start page numbering on 0 and no header nor footer on
                            first page. (default: False)
      --do-not-remove-tmp-files
  ```

- Without a flake-enabled nixpkgs install: sorry but you are on your own. I
  very much welcome pull requests adding instructions for how to install or run
  on other systems.

¹ This one should work-out-of-the box:

<https://github.com/DeterminateSystems/nix-installer>
