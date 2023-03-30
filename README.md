# Nix Literate Programming Environment

Literate programming is the upside - down inverse of what a computer expects. It presents the code to a human audience and adds a build step to help the computer figure it out.

## Reference material

* [tangledown.py](https://github.com/rebcabin/tangledown)

Building a parser (combinator)
* [nix parsec](https://github.com/kanwren/nix-parsec/blob/master/parsec.nix)
* [nom-rs](https://github.com/rust-bakery/nom)
* [hasura parser-combinator](https://hasura.io/blog/parser-combinators-walkthrough/)
* [functional parsers](http://cmsc-16100.cs.uchicago.edu/2017/Lectures/17/parsers.pdf)
* [monadic runtime](https://dev.to/javalin/zero-boilerplate-zero-runtime-errors-coding-with-monads-26n9)
* [frontmatter - markdown cms](https://frontmatter.codes/)
* [structure editor](https://en.wikipedia.org/wiki/Structure_editor)
* [1982 Syntax-directed editing--towards integrating programming environments](https://apps.dtic.mil/sti/pdfs/ADA117970.pdf)
* [axiom - computer algebra system](https://github.com/daly/axiom)



## Goal

1. Source markdown files are tangled into an executable form
2. The source markdown files always remain readable
3. Build setup requires few dependencies

### Syntax / Parsing

Markdown is read line by line. Language hints on code blocks invoke actions by  "parameter" and the body of the code block is passed in as well

Each handler retains state per file, perhaps implemented as a continuation? Monad?

Handlers might output "execution results" which are included after the file

All "input" to a handler is hashed and referenced after the tag

If the "input hash" doesn't match then the handler is run again



### Runtime / Tangling



### Results / Weaving



## Optimistic Programming Example

The `bash` handler runs the command and passes the code block to stdin

TODO: how to maintain purity?

<nixmd import="nix/markdown.nix" />

```bash nix shell nixpkgs#hello
hello --greeting "GOSH HI THERE"
```

<!-- some hash -->
<code>
GOSH HI THERE
</code>
<!-- /some hash -->

## Use case

Add linting to a project README and solicit help

+++
toml = "ok"
+++

# Outstanding questions

* How do various markdown renderers deal with:
    * extra text after language name
    * comments
    * tags
    * data in tags
* How do handlers pass state?
* How do handlers refer to each other?
* How to "enforce" handler purity?
* How are hashes computed?

## Philosophy

```
 synchronous semantics
asynchronous operations
```

source code runtime

(via axiom)[https://github.com/daly/axiom]:
> To quote Fred Brooks, "The Mythical Man-month"
>
>  "A basic principle of data processing teaches the folly of trying to
>   maintain independent files in synchronization... Yet our practice in
>   programming documentation violates our own teaching. We typically
>   attempt to maintain a machine-readable form of a program and an
>   independent set of human-readable documentation, consisting of prose
>   and flowcharts ... The solution, I think, is to merge the files, to
>   incorporate the documentation in the source program."
>
> "A common fallacy is to assume authors of incomprehensilbe code
> will somehow be able to express themselves lucidly and clearly
>  in comments." -- Kevlin Henney
>
>   "A programmer who cannot explain their ideas clearly in natural
>    language is incapable of writing readable code." -- Tim Daly

A sufficiecntly lucid explanation of what your program does can be interpreted to be the source code



### Optimization

Handler input should be deterministic and lazily evaluated

# Implementation

## Bootstrap

Implement a subset in nix, enough to establish the build environment

This can compromize full syntax as long as it still achieves identical evaluation

It should fit into a single file less than 500 lines

## Testing

```
nix eval --impure --expr 'import ./nix/markdown.test.nix {}'
```

# Terms

* Source Text - the original markdown
* Tangle - transform source markdown into executable files
* Weave - derive additional human readable markdown from source
* Handler - is fed inptu from the markdown maintains state
* Frontend - has a runtime for that language

# Nontrivial demonstration

Itself in rust

* dependency on an operating system call
* described functionally as a monad on a process
* that executes asynchronously
* matching source text in a file
* producing output that matches an artifact

https://doc.rust-lang.org/cargo/reference/build-scripts.html

rerun-if instructions 




# Motivating project

A rust debugger

that can render interactive widgets

in a browser notebooks

based off of templates

https://rust-analyzer.github.io/

use it to build cad models

based on sdf surfaces

and derive gcode from it


resulting file
what the resulting file is in the context of the project

idealol:
https://sdfgeoff.github.io/wasm_minigames/what_its_all_about.html

