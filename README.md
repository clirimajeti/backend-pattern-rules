# Backend Pattern Rules

An agent skill that turns your backend codebase's own conventions into lint rules, each with tests.

Every codebase has conventions it mostly follows but never enforces.
Domain code takes a `Clock`, routers go through services, IDs come from one helper.
They live in review comments and in the heads of whoever was around when they were decided.

This skill finds them, asks you which ones to enforce and how, and writes one rule per convention.
The majority pattern becomes the only pattern.

It works with Java, Kotlin, Python, Go, C#, PHP, Rust, Ruby and any other language [ast-grep](https://ast-grep.github.io) parses.
For JavaScript and TypeScript, including Node backends, use the companion skill `eslint-pattern-rules`.

## Installation

### 1. Get the skill

**Claude Code**

```bash
claude plugin marketplace add clirimajeti/backend-pattern-rules
claude plugin install backend-pattern-rules@backend-pattern-rules
```

**Codex, Copilot, Cursor and others**

```bash
npx skills add clirimajeti/backend-pattern-rules
```

**Manual**

Copy `skills/backend-pattern-rules/` into your agent's skills folder, for example `~/.claude/skills/backend-pattern-rules/`.

### 2. Ask for a rule

The skill is model-invoked, so there is no command to remember.
Ask in your own words, or name it:

- "Our routers must never import repositories. Turn that into a lint rule."
- "Which of our ADRs could become lint rules?"
- "Enforce our ADR about clock injection in the backends."

## Where the rule goes

The skill picks the first option that fits:

1. **An existing check**: a rule in a linter you already run (Ruff, detekt, golangci-lint, Error Prone, analyzers) or an architecture test library you already depend on (ArchUnit, Konsist, import-linter, Deptrac).
   You get its exact config instead of a new rule, including for rules that exist but are switched off.
2. **Your own rule set**: when the project already maintains custom rules for a native tool (a detekt rule set, Error Prone checks, a flake8 plugin), the new rule is written there, in the same style, with the same tests and registration.
3. **An ast-grep rule**: one YAML rule and one YAML test, registered through `sgconfig.yml`.

## What it leaves alone

- **Build files and lockfiles.**
  ast-grep runs through `npx` or `uvx` at a pinned version, and the install command goes into the report.
- **Baselines.**
  New hits are never hidden in a baseline file without asking.
- **Your source files and hand-written rules.**
- **Your agent docs**, except the lines you approve deleting or shortening once a rule enforces them.

## How It Works

1. **Detects your setup**: languages and build tools, ast-grep, the native checks you already run, your own rule sets, decision records (ADRs), and agent docs (CLAUDE.md, AGENTS.md, Copilot and Cursor instructions).
2. **Finds the convention**: the one you named, with its real examples and every violation, or a scan for candidates.
   The scan looks at your code, your ADRs and the rules written as prose in your agent docs.
   It also checks a list of well-known clean-code, bug-prevention, security and test rules your linters have but your project doesn't use yet, with how many places each would flag today.
   It skips anything already enforced.
3. **Lets you pick** the candidates.
   Nothing is built until you pick it, unless you opt in to auto mode in `config.json`.
   Well-known rules from outside your project are always offered, never built automatically.
4. **Asks the design questions**: boundary, scope, fix, severity and rollout, each with a recommended answer and a real example from your code.
5. **Writes the rule and its test**, and registers it.
6. **Verifies** it: the tests pass, and every hit on your real code is accounted for.
7. **Offers to clean up your agent docs**: for each line the new rule now enforces, you choose to delete it, shorten it to a pointer, or keep it.
   Fewer prose rules means less context every agent session has to read.
8. **Reports** the rules, hit counts, config changes, doc lines removed, and what it did not build.

### Configuration

`skills/backend-pattern-rules/config.json` holds the defaults.
A `.backend-pattern-rules.json` at your project root overrides them per project.

```json
{ "mode": "ask", "auto": { "maxRisk": "low", "maxFlaggedFiles": 3, "adrBacked": "ask" } }
```

| Key | Meaning |
|---|---|
| `mode` | `"ask"` (default): you pick every rule. `"auto"` (opt-in): rules within the `auto` limits are built without asking. |
| `auto.maxRisk` | Highest risk built without asking: `"low"` or `"medium"`. High-risk rules always ask. |
| `auto.maxFlaggedFiles` | Most files a rule may report on day one and still be built without asking. |
| `auto.adrBacked` | `"ask"` (default): a rule an ADR or agent doc asks for goes to you like the rest. `"auto"` (opt-in): it is built without asking in either mode, unless it is high risk. |

### Layout

```
skills/backend-pattern-rules/
├── SKILL.md                    # the workflow
├── config.json                 # selection defaults
├── agents/openai.yaml          # Codex picker metadata
├── references/
│   ├── discovery.md            # candidate scan, coverage, risk, selection
│   ├── pattern-catalog.md      # signals to probe, with native checks to try first
│   └── general-rules.md        # well-known rules to suggest when the project lacks them
└── evals/                      # a test case for `claude plugin eval`
```

### Running the Evals

```bash
cd skills/backend-pattern-rules
claude plugin eval . --allow-tools Write,Edit,Bash --scaffold
```

## License

MIT
