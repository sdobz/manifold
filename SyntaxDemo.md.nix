__args:
let
  # https://github.com/NixOS/nixpkgs/blob/master/lib/list.nix
  __foldr = op: nul: list: let len = builtins.length list; fold' = n: if n == len then nul else op (builtins.elemAt list n) (fold' (n + 1)); in fold' 0;
  # https://github.com/NixOS/nixpkgs/blob/master/lib/fixed-points.nix
  __fix' = f: let x = f x // { __unfix__ = f; }; in x;
  __extends = f: rattrs: self: let super = rattrs self; in super // f self super;
  __composeExtensions = f: g: final: prev: let fApplied = f final prev; prev' = prev // fApplied; in fApplied // g final prev';
  __composeManyExtensions = __foldr (x: y: __composeExtensions x y) (final: prev: {});
  __makeExtensible = __makeExtensibleWithCustomName "extend";
  __makeExtensibleWithCustomName = extenderName: rattrs: __fix' (self: (rattrs self) // { ${extenderName} = f: __makeExtensibleWithCustomName extenderName (__extends f rattrs); });
  __overlays = [
    (final: prev: {
out = prev.out + ''plain text
'';
    })
    (final: prev: {
      param = if builtins.hasAttr "param" __args then __args.${"param"} else "default";
      number = if builtins.hasAttr "number" __args then __args.${"number"} else 1;
    })
    (final: prev: {
out = prev.out + ''
more plain text
'';
    })
    (final: prev: {
"code" = ''some code
'';
    })
    (final: prev: {
out = prev.out + ''
'';
    })
    (final: prev: {
      binding = prev.code;
      sum = prev.number + 1;
    })
    (final: prev: {
out = prev.out + ''
'';
    })
    (final: prev: {
      out = prev.out + builtins.concatStringsSep "" [
    "${final.binding} ${toString final.sum}"
  ];
    })
    (final: prev: {
out = prev.out + ''
'';
    })
  ];
  __extensions = __composeManyExtensions __overlays;
  __initialSelf = { out = ""; };
  __finalSelf = __makeExtensible (__extends __extensions (self: __initialSelf));
in
  __finalSelf
