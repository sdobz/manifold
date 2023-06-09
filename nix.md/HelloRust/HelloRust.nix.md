This is a more complex example demonstrating how to construct a source folder, then use a toolchain to build those files.

It highlights the out-of-order nature of literate programming and establishes some fundamental patterns of manifold.

```rust
fn main() {
  println!("Hello, World!");
}
```
<let demoRust='buildRust "hello" prev.rust' />

When compiled and built this produces

<io println='code (captureStdout "${final.demoRust}/bin/hello")' /><!-- io -->
```
Hello, World!

```
<!-- /io -->

The above output depends on a prelude, defined here

```nix
pkgs: rec {
  code = text: "`"+"``\n${text}\n``"+"`";
  captureStdout = cmd: import (pkgs.runCommand "stdout" {}
    "echo -n \"\\\"\" > $out; ${cmd} >> $out; echo -n \"\\\"\" >> $out");
  buildRust = name: srcText:
    let
      srcFile = pkgs.writeText "${name}-src" srcText;
    in
      pkgs.runCommandCC "${name}" {} ''
        mkdir -p "$out/bin"
        ${pkgs.rustc}/bin/rustc ${srcFile} -o "$out/bin/${name}"
      '';
}
```

This prelude is then injected into the global context

<with
  pkgs='import <nixpkgs> {}'
  prelude='import (pkgs.writeText "helloRustPrelude" prev.nix) pkgs'
  captureStdout='prelude.captureStdout'
  buildRust='prelude.buildRust'
  code='prelude.code'
/>
