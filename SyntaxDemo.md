plain text
<arg param="default" number='1' />
more plain text
```code
some code
```
<let binding='prev.code' sum='prev.number + 1' />
<nix eval="${final.binding} ${toString final.sum}" />
