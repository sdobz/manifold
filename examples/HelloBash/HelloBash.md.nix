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
    (final: prev: rec {
out = prev.out + ''This example shows how to capture the stdout of a bash script

'';
    })
    (final: prev: rec {
      pkgs = if builtins.hasAttr "pkgs" __args then __args.${"pkgs"} else import <nixpkgs> {};
    })
    (final: prev: rec {
out = prev.out + ''

First define the shell script

'';
    })
    (final: prev: rec {
bash = ''hello'';
out = prev.out + ''```bash
hello
```'';
    })
    (final: prev: rec {
out = prev.out + ''

Then define a derivation using the script value as source text

'';
    })
    (final: prev: rec {
      demoScript = prev.pkgs.writeShellApplication {
    name="demoScript";
    text=prev.bash;
    runtimeInputs=[prev.pkgs.hello];
    checkPhase=null;
};
    })
    (final: prev: rec {
out = prev.out + ''

```
'';
    })
    (final: prev: rec {
      out = prev.out + builtins.concatStringsSep "" [
    (prev.demoScript)
  ];
    })
    (final: prev: rec {
out = prev.out + ''
```

Next define a builder that captures the stdout of that script into an importable file

'';
    })
    (final: prev: rec {
      capturingBuilder = prev.pkgs.runCommand
    "capturingBuilder" {}
    "echo -n \\\" > $out; ${prev.demoScript}/bin/demoScript >> $out; echo -n \\\" >> $out"
;
    })
    (final: prev: rec {
out = prev.out + ''

```
'';
    })
    (final: prev: rec {
      out = prev.out + builtins.concatStringsSep "" [
    (prev.capturingBuilder)
  ];
    })
    (final: prev: rec {
out = prev.out + ''
```

Finally that file is imported, showing the scripts output

```
'';
    })
    (final: prev: rec {
      out = prev.out + builtins.concatStringsSep "" [
    (import (prev.capturingBuilder))
  ];
    })
    (final: prev: rec {
out = prev.out + ''
```
'';
    })
  ];
  extensions = composeManyExtensions overlays;
  initialSelf = { out = ""; };
  finalSelf = makeExtensible (extends extensions (self: initialSelf));
}; in
  nixmd.finalSelf
