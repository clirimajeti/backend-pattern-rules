# General rules

Well-known rules worth suggesting when a project does not use them yet, whatever its code mostly does today.
Almost all of them already exist in a linter the project may run, so a suggestion is usually a config entry, not a custom rule.
A rule from a linter the project does not run is never installed: it goes into the report as an option, with its install command.
ast-grep is the exception, because it needs no project change: a rule only ast-grep can express is still a candidate.

Count today's hits without touching the project's config:
- **Ruff**: `ruff check --select C901 --config 'lint.mccabe.max-complexity = 10' --statistics`.
- **golangci-lint**: run with only that linter enabled (`golangci-lint run --enable-only gocyclo` in recent versions).
- **detekt, PMD, Checkstyle, Roslyn**: the Gradle or Maven task has no per-run override, so run the tool's CLI with a config file in the scratchpad, never in the repo.
  When that is not practical, count with ast-grep or `rg` and label the number as approximate.
  When nothing can approximate it (cognitive complexity, type-based rules), report "not counted" and why.
- **File and function length**: `wc -l` and the tool's own report are enough.

For a limit, offer two starting values: the standard one below, with its hit count, and the strictest value the code already meets, which starts at zero hits.
Get the strictest value from a run with the limit set to 1: the findings carry each function's actual value, and the maximum is the strictest value with zero hits.
Count all candidate rules of one tool in a single run where the tool allows it.
A rule that would fail the build on day one also gets the rollout question from SKILL.md step 3.

## Clean code limits

| Rule | Kotlin (detekt) | Python (Ruff) | Go (golangci-lint) | Java / C# | Standard value |
|---|---|---|---|---|---|
| Cyclomatic complexity | `CyclomaticComplexMethod` | `C901` | `gocyclo` | PMD `CyclomaticComplexity`, `CA1502` | 10-15 |
| Nesting depth | `NestedBlockDepth` | - | `nestif` | Checkstyle `NestedIfDepth` | 4 |
| Function length | `LongMethod` | `PLR0915` | `funlen` | PMD `NcssCount` | 50-60 lines |
| Parameters per function | `LongParameterList` | `PLR0913` | - | PMD `ExcessiveParameterList` | 5, then a parameter object |
| Returns per function | `ReturnCount` | `PLR0911` | - | - | 3 |
| No `else` after `return` | - | `RET505` | `revive` `early-return` | - | on |
| Unused code | `UnusedPrivateMember`, `UnusedImports` | `F401`, `F841` | `unused` | IDE / compiler warnings | on |
| Magic numbers | `MagicNumber` | `PLR2004` | `mnd` | Checkstyle `MagicNumber` | on, tests excluded |

## Agent-friendly code

Code an agent can read whole and change locally costs fewer tokens per task.

| Rule | Check first | Standard value |
|---|---|---|
| File and class size | detekt `LargeClass`, `TooManyFunctions`; elsewhere `wc -l` in the report | about 400-600 lines |
| No commented-out code | Ruff `ERA001`; elsewhere a custom rule (the project's own rule set, else ast-grep on `kind: comment`) | on |
| No leftover debug output | Ruff `T201`, `forbidigo` on `^fmt\.Print`, detekt `ForbiddenMethodCall` on `println` | on outside scripts and tests |
| Generated code is excluded | the linter's `excludes` for every generated folder | present |

## Bug-prevention basics

| Rule | Check first |
|---|---|
| No swallowed exceptions | detekt `SwallowedException`, `EmptyCatchBlock`; Ruff `S110`, `BLE001`, `E722`; `errcheck`; PMD `EmptyCatchBlock`; `CA1031` |
| No forced null dereference | detekt `UnsafeCallOnNullableType` |
| No unreachable or dead branches | detekt `UnreachableCode`; `staticcheck`; `govet` |
| No mutable default arguments | Ruff `B006` |
| Timezone-aware datetimes | Ruff `DTZ` rules |
| `equals` with `hashCode` | detekt `EqualsWithHashCodeExist`; Error Prone `EqualsHashCode` |
| Outgoing HTTP calls set a timeout | Ruff `S113`; `noctx` |
| Resources are closed | Ruff `SIM115`; PMD `CloseResource`; `bodyclose` |

## Security basics

| Rule | Check first |
|---|---|
| The security rule set of the linter in use | Ruff `S` (bandit), `gosec`, find-sec-bugs (SpotBugs), .NET `CA2100` / `CA53xx` |
| No SQL built from strings | Ruff `S608`, `gosec` `G201`/`G202`, find-sec-bugs |
| No shell commands from strings | Ruff `S602`/`S605`, `gosec` `G204` |
| TLS verification stays on | Ruff `S501`, `gosec` `G402` |
| No secrets in source | a secret scanner in CI (gitleaks, trufflehog), report only |

## Test hygiene

| Rule | Check first |
|---|---|
| No skipped tests without a reason | an ast-grep rule on `@Disabled` / `@Ignore` / `pytest.mark.skip` / `t.Skip` without a reason argument |
| No sleeps in tests | detekt `ForbiddenMethodCall` on `Thread.sleep` when detekt reads test sources; else an ast-grep rule scoped to test folders |
| pytest style | Ruff `PT` rules |
| Go test helpers and parallel tests | `thelper`, `tparallel`, `testifylint` |
