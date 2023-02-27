{
  description = "literate programming in markdown using nix";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem
    [
      flake-utils.lib.system.x86_64-linux
    ]
    (
      system: let {
        pkgs = nixpkgs.legacyPackages.${system};

        markdown = pkgs.callPackage nix/markdown.nix {  };

        packages = {};

        devShell =
          pkgs.mkShell {
            buildInputs = with pkgs; [
            ];
            buildPhase = "";
            shellHook = '''';
          };
      }
    )
  };
}
