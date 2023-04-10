This example shows how to capture the stdout of a bash script



First define the shell script

```bash
hello
```

Then define a derivation using the script value as source text



```
/nix/store/29rdyfcqag8jvdks43fjijgc9z32cqsj-demoScript
```

Next define a builder that captures the stdout of that script into an importable file



```
/nix/store/1y7lp0plb7b6hyml3c10vcg3ylj8r8wh-capturingBuilder
```

Finally that file is imported, showing the scripts output

```
Hello, world!

```
