# What are Flakes

Flakes are an idiomatic way to pin nix dependencies

## How do they integrate

Each `.nix.md` file defines a single flake. The `<flake />` tag allows the user to define properties such as `<flake name='"HelloFlake"' />`

## Multi step

<flake inputs.hello='./input.txt' />