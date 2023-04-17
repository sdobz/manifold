This example shows how to capture the stdout of a bash script

<with pkgs='import <nixpkgs> {}' />

First define the shell script

```bash
hello
```

Then define a derivation using the script value as source text

<let demoScript='pkgs.writeShellApplication {
    name="demoScript";
    text=prev.bash;
    runtimeInputs=[pkgs.hello];
    checkPhase="";
}' />

```
<io print='prev.demoScript' />
```

Next define a builder that captures the stdout of that script into an importable file

<let capturingBuilder='pkgs.runCommand
    "capturingBuilder" {}
    "echo -n \\\" > $out; ${prev.demoScript}/bin/demoScript >> $out; echo -n \\\" >> $out"
' />

```
<io print='prev.capturingBuilder' />
```

Finally that file is imported, showing the scripts output

```
<io print='import (prev.capturingBuilder)' />
```
