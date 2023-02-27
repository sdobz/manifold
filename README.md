# Nix Literate Programming Environment

Literate programming is the upside - down inverse of what a computer expects. It presents the code to a human audience and adds a build step to help the computer figure it out.

## Reference material

* [tangledown.py](https://github.com/rebcabin/tangledown)

## Goal

1. Source markdown files are tangled into an executable form
2. The source markdown files evaluate to something easily grokable
3. Build setup requires few dependencies

## Optimistic Programming Example

```md
<include src="" />
```
<!-- some hash -->
<md>
</md>

```bash nix -p hello
hello
```
<!-- some hash -->
<code>
Hello, world!
</code>

### Syntax / Parsing

Markdown is read line by line. Language hints on code blocks invoke handlers by name.

These handlers are fed the code block and their output can be woven back into the source

XML tags are used to direct the system in a manner hidden from the naively rendered markdown

# Outstanding questions

### Optimization

Handler input should be deterministic and lazily evaluated

# Implementation

## Bootstrap

Implement a subset in nix, enough to establish the build environment

This can compromize full syntax as long as it still achieves identical evaluation

It should fit into a single file less than 500 lines

# Terms

* Source Text - the original markdown
* Tangle - transform source markdown into executable files
* Weave - derive additional human readable markdown from source
* Handler - is fed inptu from the markdown maintains state