# Hello World

The nix package [hello](https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/misc/hello/default.nix) <with pkgs="import <nixpkgs> {}" hello="pkgs.hello" /> builds the gnu hello world.

Any time a code block appears the text is stored in the "state" attribute set with the same tag. 

```bash
hello
```

This can be dumped with the `<nix trace="state" />` tag

```
<nix trace="state" />
```

