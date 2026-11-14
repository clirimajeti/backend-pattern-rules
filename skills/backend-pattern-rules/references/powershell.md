# PowerShell: rules for PSScriptAnalyzer

PowerShell conventions become PSScriptAnalyzer rules, never ast-grep rules: ast-grep has no PowerShell grammar.
PSScriptAnalyzer is the linter PowerShell projects already run, in the editor (the VS Code extension) and in CI, so a rule here works in all three places and in the `codemyrules` feedback loop.
This file replaces the ast-grep parts of steps 1, 2, 4 and 5 for PowerShell; steps 3, 6 and 7 apply as written.

Run every command with `pwsh -NoProfile -NonInteractive -Command '...'`.
PowerShell 7 (`pwsh`) only: Windows PowerShell 5.1 cannot run the `codemyrules` loop wrapper.
When `pwsh` or the `PSScriptAnalyzer` module is missing, stop and put the install commands in the report (`Install-Module PSScriptAnalyzer -Scope CurrentUser`, `Install-Module Pester -Scope CurrentUser -SkipPublisherCheck`); never install them on your own.

## 1. Detect

- Sources: `.ps1` scripts, `.psm1` modules, `.psd1` manifests and data files; Pester tests are `*.Tests.ps1`.
- The settings file: `PSScriptAnalyzerSettings.psd1` (the name the VS Code extension and most CI steps use), or the path after `-Settings` in a CI step, a build script (`build.ps1`, `*.build.ps1`, psake, Invoke-Build) or `.vscode/settings.json` (`powershell.scriptAnalysis.settingsPath`).
  Note its keys: `IncludeRules`, `ExcludeRules`, `Severity`, `Rules` (per-rule options), `CustomRulePath`, `IncludeDefaultRules`.
- The project's own rule module: the paths in `CustomRulePath`, usually a `.psm1` with `Measure-*` functions.
  When it exists, it is the project's rule set: new rules go there, in its style (step 2 of the skill).
- How it runs: `Invoke-ScriptAnalyzer` in CI or a build script, with which settings, and whether CI fails on findings (`-EnableExit`, or a count check).
- Versions: `(Get-Module -ListAvailable PSScriptAnalyzer, Pester).Version`.
- The built-in rules of the installed version: `Get-ScriptAnalyzerRule | Select-Object RuleName, Severity, Description`.
  Use this list, not memory: rules differ between versions.

## 2. Pick the cheapest form

For each convention, in this order:
1. **A built-in rule, already enabled**: `covered`.
2. **A built-in rule, not enabled or not configured**: `built, not enabled`.
   The candidate is the settings change: the rule name in `IncludeRules` (or out of `ExcludeRules`), and its options under `Rules`.
3. **A custom rule**: a `Measure-*` function in the project's rule module, or a new module when there is none.
4. **Not lintable**: a convention about intent, naming quality or design stays in the docs; say so in the report.

Built-in rules that cover common PowerShell standards (check each one against `Get-ScriptAnalyzerRule` first):

| Standard | Built-in rule | Options under `Rules` |
|---|---|---|
| Approved verbs, singular nouns | `PSUseApprovedVerbs`, `PSUseSingularNouns` | |
| No aliases in scripts (`gci`, `%`, `?`) | `PSAvoidUsingCmdletAliases` | `allowlist` |
| Named parameters, not positional | `PSAvoidUsingPositionalParameters` (Information); it fires only at 3 or more positional arguments, so `Get-Service $Name` passes: a stricter standard needs a custom rule | `CommandAllowList` |
| Brace style (OTBS, Allman) | `PSPlaceOpenBrace`, `PSPlaceCloseBrace` | `Enable`, `OnSameLine`, `NewLineAfter` |
| Indentation | `PSUseConsistentIndentation` | `Enable`, `IndentationSize`, `Kind` |
| Whitespace around operators and braces | `PSUseConsistentWhitespace` | `Enable`, `CheckOperator`, `CheckSeparator` and others |
| Line length | `PSAvoidLongLines` | `Enable`, `MaximumLineLength` |
| Cmdlet and parameter casing | `PSUseCorrectCasing` (Information) | `Enable` |
| No `Write-Host` | `PSAvoidUsingWriteHost` | |
| No empty `catch` | `PSAvoidUsingEmptyCatchBlock` | |
| No `Invoke-Expression` | `PSAvoidUsingInvokeExpression` | |
| No global variables | `PSAvoidGlobalVars` | |
| No plain-text passwords | `PSAvoidUsingPlainTextForPassword`, `PSAvoidUsingConvertToSecureStringWithPlainText` | |
| `ShouldProcess` on state-changing functions | `PSUseShouldProcessForStateChangingFunctions` | |
| `[CmdletBinding()]` on functions | none: a custom rule | |
| Comment-based help | `PSProvideCommentHelp` (Information) | `Enable`, `ExportedOnly`, `Placement` |
| Single quotes for constant strings | `PSAvoidUsingDoubleQuotesForConstantString` (Information) | `Enable` |
| No `;` line endings, no trailing whitespace | `PSAvoidSemicolonsAsLineTerminators`, `PSAvoidTrailingWhitespace` (Information) | |
| Runs on a target PowerShell version | `PSUseCompatibleSyntax`, `PSUseCompatibleCommands` | `TargetVersions` / `TargetProfiles` |

Built-in rules have a fixed message and a fixed severity:
- The message cannot name the project's doc, so step 6 never offers to delete the doc line: offer the pointer or keep.
- The severity cannot be changed: most are `Warning`, some common ones only `Information`.
  The `codemyrules` loop blocks on every finding of the rules its settings file includes, so an `Information` rule is enough there.
  When CI fails only on `Error`, say in the report that such a rule does not fail CI, or offer a custom rule at `Error` as a design question.

## 3. Write a custom rule and its test

Files, beside the existing ones when the project has a rule module:

```
PSScriptAnalyzerRules/<Project>Rules.psm1        every rule of the project, one function each
PSScriptAnalyzerRules/tests/<RuleName>.Tests.ps1   one Pester file per rule
```

The rule, with the name `Measure-<Name>` (the project's own naming wins) and `RuleName` the same as the function name:

```powershell
<#
.SYNOPSIS
    Module code writes output through Write-Information, not Write-Host (STYLE.md: Output).
#>
function Measure-NoWriteHost {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.Language.ScriptBlockAst]$ScriptBlockAst
    )
    $ScriptBlockAst.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.CommandAst] -and $node.GetCommandName() -eq 'Write-Host'
    }, $false) | ForEach-Object {
        [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
            Message  = 'Use Write-Information, not Write-Host (STYLE.md: Output).'
            Extent   = $_.Extent
            RuleName = 'Measure-NoWriteHost'
            Severity = 'Error'
        }
    }
}
Export-ModuleMember -Function Measure-*
```

The gotchas that bite here:
- PSScriptAnalyzer calls the function once for every node of its parameter type in the file, nested ones included.
  With a `ScriptBlockAst` parameter, search with `FindAll(<predicate>, $false)`: `$true` also searches nested script blocks, which get their own call, so a hit inside a function is reported twice.
  A narrower parameter type (`FunctionDefinitionAst`, `CommandAst`, `ParamBlockAst`) is called per such node and needs no `FindAll`.
- The parameter type must be an exact AST class from `System.Management.Automation.Language`, and the function must be exported, or PSScriptAnalyzer silently skips it.
- `GetCommandName()` returns the name as written: compare case-insensitively (PowerShell's `-eq` already does) and decide in step 3 whether aliases and module-qualified names (`Microsoft.PowerShell.Utility\Write-Host`) count.
- The reported rule name is whatever the rule puts in `RuleName`: a literal gives that name, while `$PSCmdlet.MyInvocation.InvocationName`, common in existing rule modules, gives `<Module>\Measure-<Name>`, because PSScriptAnalyzer calls rules module-qualified.
  Suppressions and the loop's baseline ids use the reported name; `IncludeRules` takes only the plain function name, and a qualified one matches nothing, silently.
  In an existing module, follow its style and read the names from a real run.
- The `Extent` decides the reported line: use the smallest node that shows the problem.
- Severity is `Error` unless the user chose otherwise: the loop and most CI steps act on it.
- The message names the source (the ADR or the doc line it replaces), as step 3 of the skill requires.

The test runs the rule on snippets, with the same `valid` and `invalid` coverage as an ast-grep test:

```powershell
BeforeAll {
    $rules = Join-Path $PSScriptRoot '..' '<Project>Rules.psm1'
    function Find($code) { Invoke-ScriptAnalyzer -ScriptDefinition $code -CustomRulePath $rules -IncludeRule 'Measure-NoWriteHost' }
}
Describe 'Measure-NoWriteHost' {
    It 'flags <code>' -ForEach @(
        @{ code = "Write-Host 'x'" }
        @{ code = "function Get-X { Write-Host 'x' }" }
    ) { (Find $code).Count | Should -Be 1 }
    It 'allows <code>' -ForEach @(
        @{ code = "Write-Information 'x'" }
        @{ code = "'Write-Host is banned'" }
    ) { Find $code | Should -BeNullOrEmpty }
}
```

Register the rule without asking: the module path in `CustomRulePath`, and the rule name in `IncludeRules` when the settings file has one (main or suggestions, below).
With `CustomRulePath`, PSScriptAnalyzer runs no built-in rule, not even one named in `IncludeRules`, unless the settings also say `IncludeDefaultRules = $true`.
So add `IncludeDefaultRules = $true` together with `CustomRulePath`, and check after step 4 that the built-in rules still report.
Module manifests (`.psd1` files with `ModuleVersion`) stay byte-identical, like every build file.

**Suggestions layer**, for a rule the existing code breaks: a `.psd1` cannot extend another, so `PSScriptAnalyzerSettings.suggestions.psd1` is a copy of the main settings with the suggestion rules added.
The main settings stay as they are, so CI and the editor see only the main rules; the loop runs the suggestions file.
When a rule's open hits reach 0, move it to the main settings.

## 4. Verify

1. `Invoke-Pester PSScriptAnalyzerRules/tests -Output Detailed` until every case passes.
2. Run the rule over the real code: `Invoke-ScriptAnalyzer -Path . -Recurse -Settings <settings> | Where-Object RuleName -eq '<RuleName>'`.
   Leave out vendored and generated folders, and count the hits.
3. Account for every hit, as step 5 of the skill says: a false positive becomes an `allows` case and a rule fix, a missed file an `flags` case.
4. Run `Invoke-ScriptAnalyzer -Path . -Recurse -Settings <settings>` once with the main settings, to confirm the file loads and nothing new appears there for a suggestion rule.

A suppression is `[Diagnostics.CodeAnalysis.SuppressMessageAttribute('<RuleName>', '<target>')]` on a function or `param()` block; never add one on your own.

## The feedback loop entry

For the `codemyrules` loop, PSScriptAnalyzer runs at the end of each turn, through the wrapper the `codemyrules` package ships:

```json
{ "name": "psscriptanalyzer", "format": "psscriptanalyzer", "tier": "full", "extensions": [".ps1", ".psm1"],
  "command": ["pwsh", "-NoProfile", "-NonInteractive", "-File", ".claude/codemyrules/pkg/skills/codemyrules/scripts/core/psscriptanalyzer.ps1", "-Settings", "PSScriptAnalyzerSettings.suggestions.psd1", "{files}"] }
```

Protect the settings files and the rule module: `**/PSScriptAnalyzerSettings*.psd1`, `PSScriptAnalyzerRules/**`.
