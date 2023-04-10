This example shows how to capture the stdout of a bash script

<arg pkgs='import <nixpkgs> {}' />

First define the shell script

```bash
hello
```

Then define a derivation using the script value as source text

<let demoScript='prev.pkgs.writeShellApplication {
    name="demoScript";
    text=prev.bash;
    runtimeInputs=[prev.pkgs.hello];
    checkPhase=null;
}' />

```
<nix print='prev.demoScript' />
```

Next define a builder that captures the stdout of that script into an importable file

<let capturingBuilder='prev.pkgs.runCommand
    "capturingBuilder" {}
    "echo -n \\\" > $out; ${prev.demoScript}/bin/demoScript >> $out; echo -n \\\" >> $out"
' />

```
<nix print='prev.capturingBuilder' />
```

Finally that file is imported, showing the scripts output

```
<nix print='import (prev.capturingBuilder)' />
```
