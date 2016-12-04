# RbxGitHubCloner
Clone a GitHub repository to ROBLOX Studio.

Download the plugin [here](https://www.roblox.com/library/565656434/GitHub-Cloner); HTTP requests must be enabled for it to work.

Files will be cloned to the selected target object if they have a `.lua` or `.rbxs` file extension. By default they will be `Script` instances; you have two options for correcting this:

1. Change the file's name to include the desired type. `SomeModule.lua` becomes `SomeModule.mod.lua`, `SomeLocalScript.lua` becomes `SomeLocalScript.local.lua`, etc.
2. Add a comment (near the top of the file is preferable) that looks like this:

```
--# type=mod
```

ModuleScripts have the following shorthands:

* `mod`
* `module`

LocalScripts have the following shorthands:

* `loc`
* `local`