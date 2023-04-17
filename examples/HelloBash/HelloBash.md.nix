__args:
let nixmd = rec {
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
          "This example shows how to capture the stdout of a bash script\n\n\nFirst define the shell script:\n\n"
      ];
    })

    (final: prev: with final.global; rec {
      bash = "hello";
      out = prev.out + builtins.concatStringsSep "" [
          "```bash\nhello\n```"
      ];
    })

    (final: prev: with final.global; rec {
      out = prev.out + builtins.concatStringsSep "" [
          "\n\nThen define a nix derivation that runs the shell script\n\n"
      ];
    })

    (final: prev: with final.global; rec {
      global.pkgs = if builtins.hasAttr "pkgs" __args then __args.${"pkgs"} else import <nixpkgs> {};
      global.code = if builtins.hasAttr "code" __args then __args.${"code"} else code: "```\n${code}\n```";
      out = prev.out + builtins.concatStringsSep "" [
          "<with\n    pkgs='import <nixpkgs> {}'\n    code='code: \"```\\n\${code}\\n```\"'\n/>"
      ];
    })

    (final: prev: with final.global; rec {
      out = prev.out + builtins.concatStringsSep "" [
          "\n\n"
      ];
    })

    (final: prev: with final.global; rec {
      demoScript = pkgs.writeShellApplication {
    name="demoScript";
    text=prev.bash;
    runtimeInputs=[pkgs.hello];
    checkPhase="";
};
      out = prev.out + builtins.concatStringsSep "" [
          "<let demoScript='pkgs.writeShellApplication {\n    name=\"demoScript\";\n    text=prev.bash;\n    runtimeInputs=[pkgs.hello];\n    checkPhase=\"\";\n}' />"
      ];
    })

    (final: prev: with final.global; rec {
      out = prev.out + builtins.concatStringsSep "" [
          "\n\n"
      ];
    })

    (final: prev: with final.global; rec {
      out = prev.out + builtins.concatStringsSep "" [
          "<io println='code prev.demoScript' />"
          "<!-- io -->"
          "\n"
          (code prev.demoScript)
          "\n"
          "<!-- /io -->"
      ];
    })


    (final: prev: with final.global; rec {
      out = prev.out + builtins.concatStringsSep "" [
          "\n\nNext define a builder that captures the stdout of that script into an importable file\n\n"
      ];
    })

    (final: prev: with final.global; rec {
      capturingBuilder = pkgs.runCommand
    "capturingBuilder" {}
    "echo -n \\\" > $out; ${prev.demoScript}/bin/demoScript >> $out; echo -n \\\" >> $out"
;
      out = prev.out + builtins.concatStringsSep "" [
          "<let capturingBuilder='pkgs.runCommand\n    \"capturingBuilder\" {}\n    \"echo -n \\\\\\\" > $out; \${prev.demoScript}/bin/demoScript >> $out; echo -n \\\\\\\" >> $out\"\n' />"
      ];
    })

    (final: prev: with final.global; rec {
      out = prev.out + builtins.concatStringsSep "" [
          "\n\n"
      ];
    })

    (final: prev: with final.global; rec {
      out = prev.out + builtins.concatStringsSep "" [
          "<io println='code prev.capturingBuilder' />"
          "<!-- io -->"
          "\n"
          (code prev.capturingBuilder)
          "\n"
          "<!-- /io -->"
      ];
    })


    (final: prev: with final.global; rec {
      out = prev.out + builtins.concatStringsSep "" [
          "\n\nFinally that file is imported, showing the scripts output\n\n"
      ];
    })

    (final: prev: with final.global; rec {
      out = prev.out + builtins.concatStringsSep "" [
          "<io println='code (import (prev.capturingBuilder))' />"
          "<!-- io -->"
          "\n"
          (code (import (prev.capturingBuilder)))
          "\n"
          "<!-- /io -->"
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
  nixmd.finalSelf
