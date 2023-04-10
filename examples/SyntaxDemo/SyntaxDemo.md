# Plain Markdown
<arg stringParam='"default"' number='1' />
plain text

```codeBlockId
some code
```

<let binding='prev.codeBlockId' sum='prev.number + 1' />
<nix eval='"${final.binding} ${toString final.sum}"' />
