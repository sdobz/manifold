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
          "# Plain Markdown\n"
      ];
    })

    (final: prev: with final.global; rec {
      global.stringParam = if builtins.hasAttr "stringParam" __args then __args.${"stringParam"} else "default";
      global.number = if builtins.hasAttr "number" __args then __args.${"number"} else 1;
      out = prev.out + builtins.concatStringsSep "" [
          "<with stringParam='\"default\"' number='1' />"
      ];
    })

    (final: prev: with final.global; rec {
      out = prev.out + builtins.concatStringsSep "" [
          "\nplain text\n\n"
      ];
    })

    (final: prev: with final.global; rec {
      codeBlockId = "some code";
      out = prev.out + builtins.concatStringsSep "" [
          "```codeBlockId\nsome code\n```"
      ];
    })

    (final: prev: with final.global; rec {
      out = prev.out + builtins.concatStringsSep "" [
          "\n\n"
      ];
    })

    (final: prev: with final.global; rec {
      binding = prev.codeBlockId;
      sum = number + 1;
      out = prev.out + builtins.concatStringsSep "" [
          "<let binding='prev.codeBlockId' sum='number + 1' />"
      ];
    })

    (final: prev: with final.global; rec {
      out = prev.out + builtins.concatStringsSep "" [
          "\n"
      ];
    })

    (final: prev: with final.global; rec {
      out = prev.out + builtins.concatStringsSep "" [
          "<io print='\"\${stringParam} \${final.binding} \${toString final.sum}\"' />"
          "<!-- io -->"
          ("${stringParam} ${final.binding} ${toString final.sum}")
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
