This example shows how to capture the stdout of a bash script


First define the shell script

```bash
hello
```
Then define a derivation using the script value as source text


```
/nix/store/dfyqfjcxi22mapgpshmp6nq9vc4mj39d-demoScript```

Next define a builder that captures the stdout of that script into an importable file


```
/nix/store/ig2rbxfajlv6pqnck02996z7lbpqq23p-capturingBuilder```

Finally that file is imported, showing the scripts output

```
Hello, world!
```
