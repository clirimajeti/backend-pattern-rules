# Discovery

The candidate branch of [`backend-pattern-rules`](../SKILL.md): the user asked which conventions could become rules.
Work the four steps in order.
The scan finds conventions, the coverage map keeps you from proposing what the repo already enforces, and the config decides what is built without asking.

## 1. Map what is already enforced

List every place a convention is already checked.
Each one is evidence, and each one marks its convention as **covered**:
- **ast-grep**: rules in the `sgconfig.yml` `ruleDirs`.
- **Linters and banned-API lists**:
  - Java: Checkstyle, PMD, SpotBugs, Error Prone, forbiddenapis signatures.
  - Kotlin: detekt (`detekt.yml`), ktlint.
  - Python: Ruff or flake8 and pylint config in `pyproject.toml`, `setup.cfg`, `.flake8`, `ruff.toml`, especially `flake8-tidy-imports.banned-api`.
  - Go: `.golangci.yml` (`forbidigo`, `depguard`, `gosec`, `errcheck`).
  - C#: `.editorconfig` analyzer severities, `BannedSymbols.txt`, `Directory.Build.props`.
  - PHP: `phpstan.neon` (with `disallowed-calls`), `psalm.xml`.
  - Rust: `clippy.toml` (`disallowed-methods`, `disallowed-types`).
  - Ruby: `.rubocop.yml`, Packwerk.
- **The project's own rule sets**: custom detekt rule sets, Error Prone checks, flake8 or pylint plugins, analyzers.
  Read which rules are enabled in the lint config, not just which exist.
- **Architecture checks**: ArchUnit or Konsist tests, `.importlinter` or `[tool.importlinter]`, `deptrac.yaml`, `go-arch-lint`, NetArchTest or ArchUnitNET tests, tests named `*Arch*` / `*Boundar*` / `*Layer*`.
- **CI gates**: Semgrep, CodeQL, SonarQube, secret scanners.

## 2. Scan for conventions

1. **Probe** every signal in [`pattern-catalog.md`](pattern-catalog.md) for the project's languages, with a count of the good form and the bad form.
   Keep both counts and one example file per side.
   Prefer `ast-grep run -p` counts over `rg` where comments and strings would inflate a text count.
2. **Find bypasses.**
   List the project's own wrappers (helpers in `common/`, `shared/`, `util/`, `core/`, `pkg/`, `internal/`) and count the code that goes around them: `UUID.randomUUID()` beside an `Ids.next()` helper, a raw `requests.get` beside the shared client, `os.Getenv` beside a config package.
   A wrapper most code uses is a convention.
   Each bypass is a violation.
3. **Read the decision records** for conventions they ask for.

On a large repo, split the scan by top-level module or package, with one subagent per module when serial scanning is too slow.
Keep a **scan log** (signal, counts, verdict) so the user can tell a quiet codebase from a shallow scan.

Done when every catalog signal for the project's languages has a count or a stated reason it does not apply.

## 3. Label each candidate

**Coverage:**
- `covered`: something in the map already enforces it.
  It appears only as a note.
- `built, not enabled`: a rule for it exists but is switched off or only reports as a suggestion.
  The candidate is enabling it, with its current hit count, not a new rule.
  This includes a rule enabled in only some modules.
  Its risk follows the same scale, using the hit count and majority it would enforce.
- `documented, not enforced`: a decision record asks for it and nothing fails when it is broken.
- `implicit`: the code mostly follows it, with nothing written or enforced.
- `contradicted`: the docs say X and the code mostly does Y.
  Raise it as a question to the user and build neither side.

**Risk:**
- `low`: pure syntax with a `files` scope, no fix or a provably safe fix, and 90%+ of usages already follow it.
- `medium`: needs relational rules (`inside`, `has`, `not`), import regexes per folder, or a `note`-only fix, or has an 80-90% majority.
- `high`: needs types, data flow or other files, would autofix code whose behavior could change, has under an 80% majority (a team decision, not a discovery), or flags many files.

For each candidate, also note: one sentence on why it matters in project terms, the evidence, the flagged-file count, the ADR path if any, and whether a native check the project already runs expresses it (then the candidate gets that check's exact config instead of a rule).
A `high` candidate that needs types or other files gets a native-tool recommendation instead of a rule.

## 4. Select

Read `config.json` beside `SKILL.md`.
A `.backend-pattern-rules.json` at the project root overrides its keys.

```json
{ "mode": "ask", "auto": { "maxRisk": "low", "maxFlaggedFiles": 3, "adrBacked": "auto" } }
```

- `mode`: `"ask"` puts every candidate to the user. `"auto"` builds candidates within the `auto` limits without asking.
- `auto.maxRisk`: the highest risk built without asking, `"low"` or `"medium"`. A `high` candidate always goes to the user.
- `auto.maxFlaggedFiles`: the most files a rule may report on day one and still be built without asking.
- `auto.adrBacked`: with `"auto"`, a `documented, not enforced` candidate whose risk is below `high` is built without asking, in either mode.
  With `"ask"`, it goes to the user like the rest.

Split the candidates:
- **Automatic**: those the config allows.
  Name them to the user in one line, with the reason ("auto: low risk, 1 file").
- **Offered**: the remaining rule candidates.
  Present them with `AskUserQuestion`, `multiSelect: true`, up to 4 options per question and 4 questions per call.
  Each option's label is the rule name.
  Its description is the why-sentence plus the flagged files and the risk.
  Each question stands on its own ("Which of these rules should I generate?").
- Without the tool, list the candidates in chat and ask for names.
  With nobody to answer, build the automatic set, or the single strongest candidate when that set is empty.

Done when every candidate is either built, offered and answered, handed a native config or an enable step, or noted as covered or contradicted.
