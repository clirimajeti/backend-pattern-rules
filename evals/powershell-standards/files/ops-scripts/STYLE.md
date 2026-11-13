# PowerShell coding standards

Every script and module in this repo follows these rules.

1. Never use aliases in scripts. Write `Get-ChildItem`, not `gci` or `ls`; `ForEach-Object`, not `%`.
2. Call commands with named parameters, not positional ones: `Get-Content -Path $file`, not `Get-Content $file`.
3. Every function is an advanced function: it starts with `[CmdletBinding()]`.
4. Never use `Write-Host`. Use `Write-Verbose` for progress and `Write-Information` for messages to the user.
5. Keep functions small and give them clear names.
