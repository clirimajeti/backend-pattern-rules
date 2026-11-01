# Discovery

The candidate branch of [`backend-pattern-rules`](../SKILL.md): the user asked which conventions or rules the project could add.
Work the five steps in order.
The scan finds conventions in the code, the decision records and the agent docs, the general list adds well-known rules the project lacks, the coverage map keeps you from proposing what is already enforced, and the config decides what is built without asking.

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
- **Does it actually run?** An enabled rule counts as enforced only when the lint task can run it.
  Rules that need type resolution (detekt rules marked `RequiresAnalysisApi` or needing a classpath, Error Prone checks outside the compile) do nothing under a plain lint task.
  An enabled rule with many hits in the code and no baseline entries is a sign it never runs: label it `built, not enabled` and say why.
- **Architecture checks**: ArchUnit or Konsist tests, `.importlinter` or `[tool.importlinter]`, `deptrac.yaml`, `go-arch-lint`, NetArchTest or ArchUnitNET tests, tests named `*Arch*` / `*Boundar*` / `*Layer*`.
- **CI gates**: Semgrep, CodeQL, SonarQube, secret scanners.

A rule written only in prose (an ADR, an agent doc) is not enforcement.
Tests a linter never reads (a source set it skips) are enforced only by checks that do read them, such as an ArchUnit test-architecture class.

## 2. Scan for conventions

1. **Probe** every signal in [`pattern-catalog.md`](pattern-catalog.md) for the project's languages, skipping rows whose examples and checks are all for other languages, with a count of the good form and the bad form.
   Keep both counts and one example file per side.
   Prefer `ast-grep run -p` counts over `rg` where comments and strings would inflate a text count.
2. **Find bypasses.**
   List the project's own wrappers (helpers in `common/`, `shared/`, `util/`, `core/`, `pkg/`, `internal/`) and count the code that goes around them: `UUID.randomUUID()` beside an `Ids.next()` helper, a raw `requests.get` beside the shared client, `os.Getenv` beside a config package.
   A wrapper most code uses is a convention.
   Each bypass is a violation.
3. **Read the decision records** for conventions they ask for.
4. **Read the agent docs** (the list in SKILL.md step 1), plus the docs they link to or import (`@file` lines, Markdown links to repo files), one level deep, for rule-like lines: "always", "never", "must", "don't", "use X instead of Y", "X goes through Y".
   Keep each line's file and line number, so step 6 of SKILL.md can offer to clean it up once a rule enforces it.
   Mark each line **always loaded** (a root `CLAUDE.md`, `AGENTS.md` or `GEMINI.md`, the files those import with `@file`, `.github/copilot-instructions.md`) or **on demand** (linked files, folder-level `CLAUDE.md`, instructions with an `applyTo` glob).
   Always-loaded lines cost tokens in every session; on-demand lines mostly gain enforcement.
   A line that applies only to another part of the stack (backend lines in a frontend run) is out of scope.
   A line a lint rule or architecture check can verify is a candidate.
   A line about process, tone or tools ("run the tests before committing") is not.
5. **Count suppression comments per rule** (`eslint-disable`, `@ts-expect-error`, `@Suppress`, `# noqa`, `ast-grep-ignore`, `//nolint`). Three or more for one rule mean the config fights the code: a `contradicted` candidate with "relax the rule here" or "fix the code" as the options.

On a large repo, split the scan by top-level module or package, with one subagent per module when serial scanning is too slow.
Keep a **scan log** (signal, counts, verdict) so the user can tell a quiet codebase from a shallow scan.

Done when every catalog signal for the project's languages has a count or a stated reason it does not apply, and every rule-like agent-doc line is a candidate or has a reason it is not.

## 3. Check the general rules

Go through [`general-rules.md`](general-rules.md) family by family, for the project's languages.
For each rule a tool the project already runs can check, and the coverage map does not already have, count today's hits the way shown there, without changing the project's config.
Each one becomes a `general, not used` candidate, unless the project already has it in an optional config or switched off: then it is `built, not enabled` and goes with the project candidates with its hit count, or with "not counted" and the reason when no practical way to count exists: never an estimate dressed as a count.
A rule that needs a tool the project does not run goes into the report as an option, with its install command, and is not a candidate.

Done when every general rule is a candidate, already covered, or reported as needing a tool.

## 4. Label each candidate

**Coverage:**
- `covered`: something in the map already enforces it.
  It appears only as a note.
- `built, not enabled`: a rule for it exists but only runs in some modules or only reports as a suggestion, or its tool is configured but never run.
  The candidate is enabling it, with its current hit count, not a new rule.
  A rule from an installed plugin that no enabled preset turns on is `general, not used`, offered with its hit count.
- `switched off`: the config turns the rule off on purpose (`'off'` or `0`, often with a comment). Offer it after the other project candidates, with the reason if the config gives one, since someone decided against it.
  This includes a rule enabled in only some modules.
  Its risk follows the same scale, using the hit count and majority it would enforce.
- `documented, not enforced`: a decision record or an agent doc asks for it and nothing fails when it is broken.
- `implicit`: the code mostly follows it, with nothing written or enforced.
- `general, not used`: a rule from the general list that the project does not run.
- `contradicted`: the docs say X and the code mostly does Y, a cluster of suppression comments fights a rule,, or the docs ask for a check the lint config deliberately turns off.
  Raise it as a question to the user and build neither side.

**Risk:**
- `low`: pure syntax with a `files` scope, no fix or a provably safe fix, and 90%+ of usages already follow it.
- `medium`: needs relational rules (`inside`, `has`, `not`), import regexes per folder, or a `note`-only fix, or has an 80-90% majority.
- `high`: needs types, data flow or other files, would autofix code whose behavior could change, has under an 80% majority (a team decision, not a discovery), or flags more than 20 files.

A `documented, not enforced` candidate with a large legacy count is not `high` for its majority alone, because the team already decided: offer it at `warn`, or for new code only (a baseline, or an architecture test on changed files).

For each candidate, also note: one sentence on why it matters in project terms, the evidence, the flagged-file count, the ADR or agent-doc lines if any, and whether a native check the project already runs expresses it (then the candidate gets that check's exact config instead of a rule).
A `high` candidate that needs types or other files gets a native-tool recommendation instead of a rule.

## 5. Select

Read `config.json` beside `SKILL.md`.
A `.backend-pattern-rules.json` at the project root overrides its keys.

```json
{ "mode": "ask", "auto": { "maxRisk": "low", "maxFlaggedFiles": 3, "adrBacked": "ask" } }
```

- `mode`: `"ask"` (the default) puts every candidate to the user.
  `"auto"` is an opt-in that builds candidates within the `auto` limits without asking.
- `auto.maxRisk`: the highest risk built without asking, `"low"` or `"medium"`. A `high` candidate always goes to the user.
- `auto.maxFlaggedFiles`: the most files a rule may report on day one and still be built without asking.
- `auto.adrBacked`: `"ask"` (the default) treats `documented, not enforced` candidates like the rest.
  The opt-in `"auto"` builds them without asking in either mode when their risk is below `high`.

Split the candidates:
- **Automatic**: only with an opt-in above, those the config allows.
  Name them to the user in one line, with the reason ("auto: low risk, 1 file").
- **Offered**: the remaining candidates from the project itself.
  Present them with `AskUserQuestion`, `multiSelect: true`, up to 4 options per question and 4 questions per call.
  Each option's label is the rule name.
  Its description is the why-sentence plus the flagged files and the risk.
  A native config candidate is labelled by the rule plus its purpose, such as `ForbiddenMethodCall: no println outside scripts`.
  Each question stands on its own ("Which of these rules should I generate?").
  Order them by coverage (`documented, not enforced` and `built, not enabled` first), then always-loaded agent-doc lines before on-demand ones, then by risk, then by fewest flagged files.
  Offer at most 16 in one call, and list the rest in the report.
- **Contradictions**: one single-select question each, with "update the doc to match the code" and "enforce the doc" as the options.
- **General**: every `general, not used` candidate, always offered and never built automatically, in a separate call of its own questions ("Which of these rules your project doesn't use yet should I add?").
  Each option names the rule, its standard value and its hit count.
- Without the tool, list the candidates in chat and ask for names.
  Build nothing until the user answers, unless the user said to go ahead without them: then build the automatic set, or the single strongest project candidate when that set is empty, and never a general one.

A picked general or `built, not enabled` rule is a config change: enable it in the project's lint config at the agreed value and severity, with the rollout answer from SKILL.md step 3, then verify it with the project's own lint run.

Done when every candidate is either built, offered and answered, handed a native config or an enable step, or noted as covered or contradicted.
