This example shows how to capture the stdout of a bash script


First define the shell script

```bash
hello
```

Then define a nix derivation that runs the shell script

```nix
ctx: final: prev: {
    pkgs=import <nixpkgs> {};
}
```

<let demoScript='pkgs.writeShellApplication {
    name="demoScript";
    text=prev.bash;
    runtimeInputs=[pkgs.hello];
    checkPhase="";
}' />

<io println='code prev.demoScript' /><!-- io -->
```
/nix/store/29rdyfcqag8jvdks43fjijgc9z32cqsj-demoScript
```
<!-- /io -->

Next define a builder that captures the stdout of that script into an importable file

<let capturingBuilder='pkgs.runCommand
    "capturingBuilder" {}
    "echo -n \\\" > $out; ${prev.demoScript}/bin/demoScript >> $out; echo -n \\\" >> $out"
' />

<io println='code prev.capturingBuilder' /><!-- io -->
```
/nix/store/1y7lp0plb7b6hyml3c10vcg3ylj8r8wh-capturingBuilder
```
<!-- /io -->

Finally that file is imported, showing the scripts output

<io println='code (import (prev.capturingBuilder))' /><!-- io -->
```
Hello, world!

```
<!-- /io -->
