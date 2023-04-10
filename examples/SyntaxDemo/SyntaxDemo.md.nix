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
out = prev.out + ''# Plain Markdown
'';
    })
    (final: prev: rec {
      stringParam = if builtins.hasAttr "stringParam" __args then __args.${"stringParam"} else "default";
      number = if builtins.hasAttr "number" __args then __args.${"number"} else 1;
    })
    (final: prev: rec {
out = prev.out + ''
plain text

'';
    })
    (final: prev: rec {
codeBlockId = ''some code'';
out = prev.out + ''```codeBlockId
some code
```'';
    })
    (final: prev: rec {
out = prev.out + ''

'';
    })
    (final: prev: rec {
      binding = prev.codeBlockId;
      sum = prev.number + 1;
    })
    (final: prev: rec {
out = prev.out + ''
'';
    })
    (final: prev: rec {
      out = prev.out + builtins.concatStringsSep "" [
    ("${final.binding} ${toString final.sum}")
  ];
    })
    (final: prev: rec {
out = prev.out + ''
'';
    })
  ];
  extensions = composeManyExtensions overlays;
  initialSelf = { out = ""; };
  finalSelf = makeExtensible (extends extensions (self: initialSelf));
}; in
  nixmd.finalSelf
