# Plain Markdown
<with stringParam='"default"' number='1' />
plain text

```codeBlockId
some code
```

<let binding='prev.codeBlockId' sum='number + 1' />
<nix print='"${stringParam} ${final.binding} ${toString final.sum}"' />
