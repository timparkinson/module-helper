# module-tools
A collection of tools for powershell modules

## Join-PowershellDefinition

Collects files making up a powershell module, assuming a layout of `public`, `private`, `enums`, `classes` and combines them into a single module definition. This may then be output to a file or imported as a dynamic module with `New-Module`.
