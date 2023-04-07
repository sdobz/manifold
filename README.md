# Nix Literate Programming Environment

Literate programming is the upside - down inverse of what a computer expects. It presents the code to a human audience and adds a build step to help the computer figure it out.

Nix can be seen from an operational perspective as a DSL used to write build scripts. It can be fussy and hard to reason about as it must work around all of the historical cruft required to build software.

## Goal

Use markdown to describe a literate software development environment by generating nix derivations.

## Syntax / Parsing

The file is parsed once, top to bottom, and a runtime representation is built. The only syntax handled by are self closing html tags and identified code blocks

Available tags are:
* `<nix eval='<expr 1>' eval='<expr 2>' />` - evaluate an expression and include it in the output markdown
* `<arg <param>='<default expr>' ... />` - add an argument to the derivation
* `<let <binding>='"string value"' ... />`

Code blocks can be started using `` ```codeBlockId ``

### Syntax issues

All quotes are single quotes.

Including a string in the expression can be done like so:
`<let someBinding='"string ${expandion}"' />`

Remaining parser work:
* Escaping self closing html tags is currently not possible.
* Escaping single quotes is currently not possible

## Runtime / Tangling

The markdown is translated into a nix derivation, inlining expressions and wrapping each in an overlay.

### Results / Weaving


# Outstanding questions

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

A sufficiecntly lucid explanation of your programs behavior can be interpreted as the program itself

# Implementation

## Bootstrap

Implement a subset in nix, enough to establish the build environment

This can compromize full syntax (escapes etc) as long as it still achieves identical evaluation

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
* [Nixpkgs overlays are monoids ](https://www.haskellforall.com/2022/01/nixpkgs-overlays-are-monoids.html)
* [parsing the nix AST](https://medium.com/@MrJamesFisher/nix-by-example-a0063a1a4c55)
* [writing a json parser in haskell](https://hasura.io/blog/parser-combinators-walkthrough/)
* [Parsec style parser for markdown](https://github.com/tiqwab/md-parser)
* [rust webassembly what it's all about](https://sdfgeoff.github.io/wasm_minigames/what_its_all_about.html)

# Motivating project

A rust debugger

that can render interactive widgets

in a browser notebooks

based off of templates

https://rust-analyzer.github.io/

use it to build cad models

based on sdf surfaces

and derive gcode from it
