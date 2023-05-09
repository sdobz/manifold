__args:
let manifold = rec {
  args = __args;
  # https://github.com/NixOS/nixpkgs/blob/master/lib/list.nix
  foldr = op: nul: list: let len = builtins.length list; fold' = n: if n == len then nul else op (builtins.elemAt list n) (fold' (n + 1)); in fold' 0;
  # https://github.com/NixOS/nixpkgs/blob/master/lib/fixed-points.nix
  fix' = f: let x = f x // { unfix = f; }; in x;
  extends = f: rattrs: self: let super = rattrs self; in super // f self super;
  composeExtensions = f: g: final: prev: let fApplied = f final prev; prev' = prev // fApplied; in fApplied // g final prev';
  composeManyExtensions = foldr (x: y: composeExtensions x y) (final: prev: {});
  makeExtensible = makeExtensibleWithCustomName "extend";
  makeExtensibleWithCustomName = extenderName: rattrs: fix' (self: (rattrs self) // { ${extenderName} = f: makeExtensibleWithCustomName extenderName (extends f rattrs); });
  overlays = [
    (final: prev: with final.global; rec {
      out = prev.out + builtins.concatStringsSep "" [
          "This is a more complex example demonstrating how to construct a source folder, then use a toolchain to build those files.\n\nIt highlights the out-of-order nature of literate programming and establishes some fundamental patterns of manifold.\n\n"
      ];
    })

    (final: prev: with final.global; rec {
      rust = "fn main() {\n  println!(\"Hello, World!\");\n}";
      out = prev.out + builtins.concatStringsSep "" [
          "```rust\nfn main() {\n  println!(\"Hello, World!\");\n}\n```"
      ];
    })

    (final: prev: with final.global; rec {
      out = prev.out + builtins.concatStringsSep "" [
          "\n"
      ];
    })

    (final: prev: with final.global; rec {
      demoRust = buildRust "hello" prev.rust;
      out = prev.out + builtins.concatStringsSep "" [
          "<let demoRust='buildRust \"hello\" prev.rust' />"
      ];
    })

    (final: prev: with final.global; rec {
      out = prev.out + builtins.concatStringsSep "" [
          "\n\nWhen compiled and built this produces\n\n"
      ];
    })

    (final: prev: with final.global; rec {
      out = prev.out + builtins.concatStringsSep "" [
          "<io println='code (captureStdout \"\${final.demoRust}/bin/hello\")' />"
          "<!-- io -->"
          "\n"
          (code (captureStdout "${final.demoRust}/bin/hello"))
          "\n"
          "<!-- /io -->"
      ];
    })


    (final: prev: with final.global; rec {
      out = prev.out + builtins.concatStringsSep "" [
          "\n\nThe above output depends on a prelude, defined here\n\n"
      ];
    })

    (final: prev: with final.global; rec {
      nix = "pkgs: rec {\n  code = text: \"`\"+\"``\\n\${text}\\n``\"+\"`\";\n  captureStdout = cmd: import (pkgs.runCommand \"stdout\" {}\n    \"echo -n \\\"\\\\\\\"\\\" > $out; \${cmd} >> $out; echo -n \\\"\\\\\\\"\\\" >> $out\");\n  buildRust = name: srcText:\n    let\n      srcFile = pkgs.writeText \"\${name}-src\" srcText;\n    in\n      pkgs.runCommandCC \"\${name}\" {} ''\n        mkdir -p \"$out/bin\"\n        \${pkgs.rustc}/bin/rustc \${srcFile} -o \"$out/bin/\${name}\"\n      '';\n}";
      out = prev.out + builtins.concatStringsSep "" [
          "```nix\npkgs: rec {\n  code = text: \"`\"+\"``\\n\${text}\\n``\"+\"`\";\n  captureStdout = cmd: import (pkgs.runCommand \"stdout\" {}\n    \"echo -n \\\"\\\\\\\"\\\" > $out; \${cmd} >> $out; echo -n \\\"\\\\\\\"\\\" >> $out\");\n  buildRust = name: srcText:\n    let\n      srcFile = pkgs.writeText \"\${name}-src\" srcText;\n    in\n      pkgs.runCommandCC \"\${name}\" {} ''\n        mkdir -p \"$out/bin\"\n        \${pkgs.rustc}/bin/rustc \${srcFile} -o \"$out/bin/\${name}\"\n      '';\n}\n```"
      ];
    })

    (final: prev: with final.global; rec {
      out = prev.out + builtins.concatStringsSep "" [
          "\n\nThis prelude is then injected into the global context\n\n"
      ];
    })

    (final: prev: with final.global; rec {
      global.pkgs = if builtins.hasAttr "pkgs" __args then __args.${"pkgs"} else import <nixpkgs> {};
      global.prelude = if builtins.hasAttr "prelude" __args then __args.${"prelude"} else import (pkgs.writeText "helloRustPrelude" prev.nix) pkgs;
      global.captureStdout = if builtins.hasAttr "captureStdout" __args then __args.${"captureStdout"} else prelude.captureStdout;
      global.buildRust = if builtins.hasAttr "buildRust" __args then __args.${"buildRust"} else prelude.buildRust;
      global.code = if builtins.hasAttr "code" __args then __args.${"code"} else prelude.code;
      out = prev.out + builtins.concatStringsSep "" [
          "<with\n  pkgs='import <nixpkgs> {}'\n  prelude='import (pkgs.writeText \"helloRustPrelude\" prev.nix) pkgs'\n  captureStdout='prelude.captureStdout'\n  buildRust='prelude.buildRust'\n  code='prelude.code'\n/>"
      ];
    })

    (final: prev: with final.global; rec {
      out = prev.out + builtins.concatStringsSep "" [
          "\n"
      ];
    })

  ];
  extensions = composeManyExtensions overlays;
  initialSelf = { out = ""; global = {}; };
  finalSelf = makeExtensible (extends extensions (self: initialSelf));
}; in
  manifold.finalSelf
