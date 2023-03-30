{
  description = "literate programming in markdown using nix";
  inputs = {};
  outputs = { self, nixpkgs }: let
    forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "x86_64-darwin" "i686-linux" "aarch64-linux" ];
  in {
      legacyPackages = forAllSystems (system: import nixpkgs {
        inherit system;
      });

      packages = forAllSystems (system: let
        pkgs = self.legacyPackages."${system}";
        markdown_nix = ./nix/markdown.nix;
        runtimeInputs = [ pkgs.nix ];
      in {
        nixmd = pkgs.writeScriptBin "nixmd"
          ''
          #!${pkgs.runtimeShell}
          set -o errexit
          set -o nounset
          set -o pipefail

          export PATH="${pkgs.lib.makeBinPath runtimeInputs}:$PATH"

          if  [ $# -lt 1 ] || [ ! -f "$1" ]; then
              echo "Usage: $0 <somefile.md>"
              exit 1
          fi
          SOURCE_TEXT="$(realpath "$1")"
          MARKDOWN_NIX="''${MARKDOWN_NIX:-${markdown_nix}}"
          nix-instantiate --eval -E "with import \"$MARKDOWN_NIX\"; evalFile \"$SOURCE_TEXT\""
          '';
      });

      defaultPackage = forAllSystems (system: self.packages."${system}".nixmd);

      apps = forAllSystems (system: {
        nixmd = {
          type = "app";
          program = "${self.packages."${system}".nixmd}/bin/nixmd";
        };
      });
      defaultApp = forAllSystems (system: self.apps."${system}".nixmd);

      devShell =  forAllSystems (system: 
        self.legacyPackages."${system}".mkShell {
            buildInputs = [ self.packages."${system}".nixmd ];
            buildPhase = "";
            shellHook = ''
            
            '';
          }
      );
  };
}
