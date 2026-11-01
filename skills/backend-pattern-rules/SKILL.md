---
name: backend-pattern-rules
description: Turn a backend codebase's own conventions into ast-grep lint rules with tests, or into the project's existing custom rule set (detekt, Error Prone, flake8/pylint plugins and similar), for Java, Kotlin, Python, Go, C#, PHP, Rust, Ruby and other non-JS languages. Use when the user wants a custom lint rule or architecture check for backend code, asks which of their patterns, ADRs or CLAUDE.md / AGENTS.md instructions could become lint rules, asks which clean-code, bug-prevention, security or test rules the backend lacks, or wants to enforce a convention the code mostly follows.
---

# Backend Pattern Rules

A **convention** is what the codebase already mostly does, or what one of its decision records chose.
This skill encodes one convention per rule, so the majority pattern becomes the only pattern.
The project's code and decisions are the source of truth, and the user settles every design choice.
Nothing is written until the user has picked it.

A rule also saves context: a convention written as prose in CLAUDE.md or AGENTS.md is read by every agent session, while a rule costs nothing until it is broken.

Rules are written for [ast-grep](https://ast-grep.github.io): one YAML rule and one YAML test per convention, in any language ast-grep parses.
A check the project's own native linter or architecture test can already express wins over a custom rule.
When the project already maintains its own rule set for a native tool, new rules go into that rule set instead of ast-grep.
JavaScript and TypeScript, including Node backends, belong to the `eslint-pattern-rules` skill.

Count and locate with `rg -c` / `rg -n`, always with a path (in scripts, `rg` without one waits on stdin) (with several `-g` globs the last matching one wins, so put exclusions like `-g '!*.spec.ts'` after the includes), confirm structural counts with `ast-grep run -p '<pattern>' -l <lang>`, and open a file only for details a count can't give.

## 1. Detect the setup

Look each of these up rather than asking:
- **Languages and build tools**: `pom.xml`, `build.gradle(.kts)`, `pyproject.toml`, `go.mod`, `*.csproj`, `composer.json`, `Cargo.toml`, `Gemfile`.
  Note the source roots, the test folders, and generated code (`target/`, `build/`, `generated-sources/`, `migrations/`, `*_pb2.py`, `*.pb.go`).
- **ast-grep**: an existing `sgconfig.yml`, its `ruleDirs` and `testConfigs`, and how the project runs ast-grep (a pinned dependency, a CI step, a pre-commit hook).
  Find the version to use with `npm view @ast-grep/cli version` when the project pins none.
- **Native checks already configured**: linters, banned-API lists and architecture tests, per [`references/discovery.md`](references/discovery.md) step 1.
- **The project's own native rule set**, if any: a module with a detekt `RuleSetProvider`, Error Prone `BugChecker`s, a PMD XPath ruleset, a flake8 or pylint plugin, `go/analysis` analyzers, Roslyn analyzers, PHPStan rules, or RuboCop cops.
  Note its folder, base class, naming, test harness, how rules are registered and enabled, and any baseline file (`detekt-baseline.xml`, `phpstan-baseline.neon`).
- **Generated code**: generator markers such as `.yo-rc.json`, `.jhipster/`, `.openapi-generator/`, `@Generated`, or `DO NOT EDIT` headers, and the source folders each generator owns.
  A rule still guards new code there, but existing hits are fixed in the generator's template or blueprint, not by hand: say so for each hit in generated code.
- **Decision records**: `docs/adr/`, `docs/decisions/`, `notes/decisions/`, `ADR-*.md`, CONTRIBUTING.
- **Agent docs**: every `CLAUDE.md`, `AGENTS.md` and `GEMINI.md` in the repo, `.github/copilot-instructions.md`, `.github/instructions/*.md`, `.cursor/rules/`, `.cursorrules`, `.windsurfrules`.

Done when you can state each of these in one line.

## 2. Pick the convention

- **The user named one:** find 2-3 real examples of it and every violation. They become the test cases.
  Give it a coverage label from [`references/discovery.md`](references/discovery.md) step 4 first.
  `covered`: report the existing check and stop.
  `built, not enabled`: the job is enabling that rule, and how (everywhere, per module, with or without a baseline) is a design question in step 3.
  Build what the user asked for; the rest of the ADR goes into the report under "not built".
  When two ADRs say the same thing, link the newest accepted one and mention the other.
  Note every agent-doc line that states the same convention, for step 6.
- **The user wants candidates:** read [`references/discovery.md`](references/discovery.md) and follow it.
  It covers the scan of code, decision records and agent docs, the general rules from [`references/general-rules.md`](references/general-rules.md), what is already enforced, risk, the opt-in auto mode, and the selection dialog.

A tool counts as one the project **runs** when it runs in CI or a documented local check; a tool that is configured but never run (a Sonar file with no CI step), or configured for something else only (Checkstyle with just a NoHttp check), counts as `built, not enabled` for the conventions it could check.
A native check wins when a tool the project **already runs** can express the convention, including through a rule that tool has but the project has not enabled yet: a banned-API list (Ruff `TID251`, detekt `ForbiddenMethodCall`, golangci `forbidigo`/`depguard`, `BannedApiAnalyzers`, clippy `disallowed_methods`, forbiddenapis), a ready-made linter rule, or an architecture test library that is already a dependency (ArchUnit, Konsist, import-linter, Deptrac, NetArchTest).
Offer its exact config or test snippet as the candidate. Once picked, apply it and verify it with the project's own lint or test run instead of steps 4 and 5.
A tool the project does not run yet is never a reason to skip the rule: mention it in the report as an alternative instead.
ast-grep always counts as available, because it runs through `npx` without any project change.
A custom rule earns its place when the convention needs folder scoping, "only through *our* helper" logic, structural context, a tailored message or a fix.

**Where a custom rule goes:**
- **The project has its own rule set** for the language: the rule goes there, written exactly like its existing rules, per "Into the project's rule set" in step 4.
  This also opens what ast-grep cannot do when the tool can: types and resolved symbols.
- **Otherwise**: an ast-grep rule.

Done when every convention you will build has its good examples and its full violation list.

## 3. Settle the design with the user

For each rule, work through these, skipping whatever the code already answers:
- **Boundary**: what is flagged.
  Test it against the real edge cases: test code, generated code, string literals and comments, aliased and relative imports (`from .repository import`, `import x as y`), type-only imports (`if TYPE_CHECKING:`), annotations, lambdas, nested functions, and fully qualified calls (`java.time.Instant.now()`, `kotlin.io.println(...)`).
- **Scope**: which files, set through the rule's `files` and `ignores` globs.
  Folder and package names live only in those globs and in one `regex`, so another layout needs only those values edited.
- **Fix**: `fix` when behavior is provably unchanged.
  When a human should confirm, leave `fix` out and put the replacement in `note`.
- **Message, note, severity, id** (`gen-<name>` for ast-grep, the rule set's own naming otherwise).
  Severity is `error`, `warning`, `info` or `hint`.
  Only `error` fails `ast-grep scan`, so a `warning` rule does not break CI until it is promoted, or CI runs `ast-grep scan --error=gen-<name>`.
  In the project's rule set, use that tool's own severity and fail-threshold settings, and "safer" means the setting that does not fail the build.
- **Rollout**, when enabling a rule would fail the build on day one: fix the hits first, enable it with the existing hits in a baseline (new code only), or enable it per module.
- **Test code**: the tool's source-set config decides whether tests are linted at all.
  A convention that must also hold in tests a tool never reads is a design question, not something the rule can change.
  Recommend the check that already reads tests: an existing ArchUnit or Konsist test-architecture class first, else an ast-grep rule scoped to the test folders.

Ask with `AskUserQuestion`, in rounds of up to 4 questions whose prerequisites are settled.
Put your recommended answer first and label it "(Recommended)".
Show a real code example in the question or in an option's `preview`.
Without the tool, ask the same rounds as a numbered list in chat.

When the rule was selected automatically, or nobody can answer, answer with your recommendations and take the **safer** side: `note` over `fix` and the narrower scope. Severity: `error` when the rule has no open hits, because nothing old breaks and agent feedback loops that block only on errors will show it; with open hits, `warning` plus a promotion plan, and say in the report that loops blocking on errors will not show the rule until it is promoted.
Step 7 puts these answers to the user.

Done when every question has an answer and you know who gave it.

## 4. Write the rule and its tests

A rule for the project's own rule set follows [Into the project's rule set](#into-the-projects-rule-set) below.
An ast-grep rule is exactly two files, both prefixed `gen-` so generated rules stay distinct from hand-written ones:

```
<rules-dir>/gen-<name>.yml
<tests-dir>/gen-<name>-test.yml
```

`<rules-dir>` and `<tests-dir>` come from an existing `sgconfig.yml`, or else are `ast-grep/rules/` and `ast-grep/rule-tests/` at the repo root.
The rule `id` is `gen-<name>`.
One rule covers one language: when a convention spans two languages, write `gen-<name>-<lang>` per language.
Hand-written rules stay as they are.

The rule file, with only the keys the rule needs.
A comment at its top names the ADR, if any, and the values to edit for another layout:

```yaml
id: gen-no-clock-in-domain
language: Java
severity: warning
message: Domain code takes a Clock instead of reading the system clock.
note: Inject `java.time.Clock` and call `Instant.now(clock)`.
files:
  - src/main/java/com/acme/domain/**
rule:
  any:
    - pattern: Instant.now()
    - pattern: System.currentTimeMillis()
```

The gotchas that bite here:
- A `pattern` must parse as code on its own.
  When it doesn't (a method, an annotation, a class member), use `pattern: {context: '<surrounding code>', selector: <kind>}`.
  When `--debug-query=ast` shows `ERROR` nodes in a pattern, switch to `kind` plus a `regex` on the relevant child.
- Node `kind` names come from the language's tree-sitter grammar.
  Look them up with `ast-grep run -p '<sample code>' -l <lang> --debug-query=ast`, never guess.
- `$A` matches one node, `$$$A` zero or more, `$_` one without capturing.
  The same name used twice must match identical code.
- `inside` and `has` look only one level up or down unless they set `stopBy: end`.
- `field: <name>` constrains the node's position in its parent, so it belongs on the level whose node sits in that field.
  `has: {field: name}` checks only the first child in that field: on `from x import a, b` it never sees `b`.
  Drop `field` when any child may match.
- Import rules match the import node (`kind`) with `has` a child whose text matches one module-name `regex`, which covers absolute and relative forms at once.
  Test every form the language has: plain, `from`-imports, multi-name and parenthesized, aliased, wildcard, static, relative, and function-local imports.
- `f($A, $$$B)` needs the comma, so it never matches a single-argument call: add `f($A)` as a second pattern.
- A metavariable may bind a wrapper node: in Kotlin, `$S` in `f($S)` is a `value_argument`, so `constraints: {S: {kind: string_literal}}` never matches.
  Check with `--debug-query=ast`, and constrain with `regex` or `has` instead.
- A metavariable for a type or receiver also matches a qualified name: constrain it with `(^|\.)Instant$`, not `^Instant$`, so `java.time.Instant.now()` is caught too.
- `regex` is Rust regex: no lookahead or lookbehind.
- ast-grep sees one file's syntax.
  A convention that needs types, data flow or other files is not an ast-grep rule: it goes into the project's own rule set when its tool can see that, and is otherwise a native-tool recommendation in the report.

Build the tests from the real code:
- `valid`: the convention and every allowed edge case.
- `invalid`: each kind of violation.
- Write each case as a snippet that parses alone, wrapped in a class or function when the language needs it.
- Tests ignore `files` and `ignores`, so scope is checked in step 5, not here.

```yaml
id: gen-no-clock-in-domain
valid:
  - Instant.now(clock);
invalid:
  - |
    class Order { boolean expired() { return expiresAt.isBefore(Instant.now()); } }
```

**Build files stay byte-identical.**
Never add ast-grep or any other dependency to `pom.xml`, `build.gradle`, `pyproject.toml`, `go.mod`, a `.csproj`, `composer.json`, `Cargo.toml`, `Gemfile` or a lockfile.
When the project does not run ast-grep yet, call it without installing it: `npx -y -p @ast-grep/cli@x.y.z ast-grep` or `uvx --from ast-grep-cli==x.y.z ast-grep`.
Never call it as `sg`, which is a different system command on Linux.
The install command and a CI step go into the report.

Register the rule yourself, without asking: it is part of building the rule, not a design choice.
With an existing `sgconfig.yml`, the rule is picked up from its `ruleDirs`, and nothing else changes.
Without one, create `sgconfig.yml` at the repo root:

```yaml
ruleDirs: [ast-grep/rules]
testConfigs:
  - testDir: ast-grep/rule-tests
```

### Into the project's rule set

When step 2 chose the project's own rule set, its existing rules are the template, and this replaces the ast-grep files above:
- **Files**: one rule and one test, beside the existing ones, in the same language, base class, package and naming.
  The rule set's naming wins over the `gen-` prefix.
  Name the rule `Gen<Name>` only when its rules have no naming pattern to follow.
- **ADR link**: when the existing rules carry an ADR number or URL (a base class, a `url`, a message suffix), the new rule carries its ADR the same way.
- **Tests**: the rule set's own harness and style (detekt `lint()` / `compileAndLint`, Error Prone `CompilationTestHelper`, `pytest` with the plugin's fixtures, `analysistest`), with the same `valid` and `invalid` coverage as above.
- **Registration**: register the rule wherever the existing rules are registered (a `RuleSetProvider`, a service file, an entry point), and enable it in the project's lint config at the agreed severity, the same way the others are enabled.
  When rules are enabled both in a shared config and in per-module overlays, enable it at the level the rollout answer chose.
  Leave every other config entry as it is.
- **Build files** stay byte-identical here too.
  When the new rule would need a dependency the rule-set module lacks, stop and put the change into the report instead.
- **Baselines**: never add the new rule's hits to a baseline file (`detekt-baseline.xml`, `phpstan-baseline.neon`) on your own.
  Report the hits, and offer the baseline as a design question when the user wants the rule enforced only for new code.

## 5. Verify

For a rule in the project's rule set, run its module's tests, then the project's lint task over the real code (`./gradlew detekt`, `mvn compile` with Error Prone, `flake8`, `golangci-lint run`), and work through steps 4 and 5 below with that output.
A baseline can hide hits: `rg -c <rule-id>` over the baseline files first, and when they hold entries, count from a run with the baseline disabled, if the tool allows it, or report the hidden count.

1. Run `ast-grep test --skip-snapshot-tests` until the cases pass.
2. Record the snapshots with `ast-grep test --update-all`, read the generated `__snapshots__/gen-<name>-snapshot.yml`, and confirm each label (and fixed output, with `fix`) is what you expect.
   Then `ast-grep test` passes as it will in CI.
3. From the repo root, run the rule over the real code: `ast-grep scan --filter '^gen-<name>$'`.
   Add `--json=compact` to count hits.
4. Account for every hit: each one is a violation under the agreed boundary.
   A false positive becomes a `valid` test and a rule fix, then a rerun.
   A file in scope with no hit that should have one becomes an `invalid` test.
5. Run plain `ast-grep scan` once, to confirm `sgconfig.yml` loads and reports `gen-<name>`.

Done when the tests pass with snapshots, every hit is accounted for, and the project-wide scan reports the rule.

## 6. Offer the agent-doc cleanup

Only for a rule built or enabled in this run and verified (a custom rule through step 5, a config change through the project's own lint run), and only for the agent-doc lines that state the convention it now enforces.
Ask one `AskUserQuestion` per rule, quoting each line with its file and line number:
- **Delete the line**: recommended when the fix is local and mechanical, so the rule's message alone tells an agent what to do.
- **Shorten it to a pointer**, such as `Time: inject a Clock, never call now() directly (enforced by gen-no-clock-in-domain).`: recommended when the convention shapes code before it is written, so an agent that never saw it would build the wrong thing and redo it.
  The pointer goes where the agent will load it: a `CLAUDE.md` in the folder the rule applies to, or an instructions file with an `applyTo` glob for those paths.
  A pointer left only in a file the agent has to follow a link to read is not seen up front, so propose the place in the same question.
- **Keep it as it is.**

Before recommending a delete, make sure the rule's message carries what the line said, plus the ADR link if there is one.
Edit the doc only as answered, and never touch a line no verified rule covers.
With nobody to answer, change no doc and list the lines in the report.

Done when every covered line is answered or listed.

## 7. Report

Keep it short:
- each rule, with its hit count and a few hits
- where each rule went (ast-grep or the project's rule set) and why
- `sgconfig.yml` or the lint-config change, as a short diff
- the ast-grep install command and a CI step (`ast-grep test && ast-grep scan`), when the project does not run ast-grep yet
- the agent-doc lines deleted, shortened or kept, with the doc tokens removed (characters / 4), split into always-loaded and on-demand lines, since only always-loaded lines cost tokens in every session
- the bigger saving is usually not the doc tokens but the fix rounds a rule avoids: say so instead of presenting the character count as the benefit
- the general rules offered and not picked, and those that need a tool the project does not run
- native alternatives worth adopting for conventions ast-grep cannot express
- the conventions you didn't build
- whether agents get the rule's feedback while they work: when nothing lints an agent's edits before the session ends (a hook, or an instruction to run the linter before finishing), recommend one, for example the `codemyrules` feedback loop; without it a broken rule only surfaces in CI, after the session
- the scan log, if you scanned

If you answered design questions on the user's behalf, close with one `AskUserQuestion` round that presents those answers, with yours as the first option.
Apply the changes, then rerun step 5 for that rule.
With nobody to answer, end the report with those answers as a numbered list instead, each with its reason and the alternative.
