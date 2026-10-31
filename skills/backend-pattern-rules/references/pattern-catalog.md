# Pattern catalog

Signals to probe while scanning, with what makes each detectable and the native checks to look for first.
Treat them as a starting point, not a checklist: propose only what the project already mostly does, or what an ADR asks for.
Examples are given for a few languages each.
Port the signal to the project's language.

Lintability:
- **Syntax**: one file's syntax is enough.
- **Path**: syntax plus a `files` scope or an import regex.
- **Types**: needs type information.
- **Data flow**: needs to follow a value through variables.
- **Cross-file**: needs knowledge of other files.

Anything beyond Syntax and Path is a native-tool candidate, not an ast-grep rule.

## Import node kinds

Checked with `--debug-query=ast` on ast-grep 0.51.0.
Re-check with the project's version before relying on them.

| Language | Import kinds |
|---|---|
| Java | `import_declaration` |
| Kotlin | `import_header` |
| Python | `import_statement`, `import_from_statement` |
| Go | `import_spec` (inside `import_declaration`) |
| C# | `using_directive` |
| PHP | `namespace_use_declaration` |
| Rust | `use_declaration` |
| Ruby | `call` with method `require` / `require_relative` |

## Security

Native checks usually ban a sink outright.
A custom rule can allow "only through *our* safe helper".

| Pattern | Signal | Check first | Lintability |
|---|---|---|---|
| SQL only through parameters or the project's query helper | string concatenation, f-string, `format`, `+` or `String.format` passed to `execute`, `createQuery`, `createNativeQuery`, `jdbcTemplate.query`, `db.Query`, `Exec`, `FromSqlRaw` | Ruff `S608`, gosec `G201`/`G202`, find-sec-bugs, Semgrep | Syntax when built in the call, Data flow otherwise |
| No shell commands from strings | `subprocess.*(..., shell=True)`, `os.system`, `Runtime.getRuntime().exec(String)`, `exec.Command("sh", "-c", ...)`, `Process.Start` with a shell | Ruff `S602`/`S605`, gosec `G204` | Syntax |
| No unsafe deserialization | `pickle.loads`, `yaml.load` without `SafeLoader`, `ObjectInputStream.readObject`, `BinaryFormatter`, `unserialize` | Ruff `S301`/`S506`, SpotBugs, `CA2300` | Syntax |
| TLS verification stays on | `verify=False`, `InsecureSkipVerify: true`, trust-all `X509TrustManager`, `ServerCertificateCustomValidationCallback` returning `true` | Ruff `S501`, gosec `G402` | Syntax |
| No secrets in source | string literals matching key or token shapes (`sk_live_`, `AKIA`, `ghp_`, `eyJ...`), or assigned to names like `password`, `secret`, `token` | Ruff `S105`/`S106`, gosec `G101`, a secret scanner in CI | Syntax |
| Sensitive values never logged | logger calls whose arguments are named `password`, `token`, `secret`, `card` | none | Syntax |
| Every endpoint declares its authorization | a route annotation or decorator (`@GetMapping`, `@app.get`, `[HttpGet]`) without the auth annotation or dependency most endpoints carry | none | Syntax (`has` / `not has` on the method) |

## Bug prevention

| Pattern | Signal | Check first | Lintability |
|---|---|---|---|
| Domain code takes time and randomness as parameters | `Instant.now()`, `LocalDateTime.now()`, `System.currentTimeMillis()`, `datetime.now()`, `time.Now()`, `DateTime.Now`, `UUID.randomUUID()`, `uuid4()`, `random.*` in configured folders | Ruff `TID251`, detekt `ForbiddenMethodCall`, `forbidigo`, `BannedApiAnalyzers`, forbiddenapis, clippy `disallowed_methods` (all need per-folder config) | Path |
| IDs, keys and cache names come from the project's helpers | a direct UUID call or a string literal duplicating a helper's output beside the helper | none | Syntax |
| No swallowed exceptions | empty `catch`, `except: pass`, `catch (Exception e) {}` with only a log, an ignored Go `err` (`_ = err`) | Ruff `S110`/`BLE001`/`E722`, PMD `EmptyCatchBlock`, detekt `SwallowedException`, `errcheck`, `CA1031` | Syntax |
| Errors use the project's error types | `raise Exception(`, `throw new RuntimeException(`, `errors.New` where wrapped or domain errors are the norm | `errorlint`, `wrapcheck` | Syntax |
| Datetimes carry a timezone | `datetime.now()` / `datetime.utcnow()` without `tz`, `LocalDateTime` in persistence code | Ruff `DTZ` rules | Syntax |
| No blocking calls in async code | `time.sleep`, `requests.*` inside `async def`, `Thread.sleep` or `.block()` inside coroutines or reactive chains | Ruff `ASYNC` rules | Syntax (`inside` the async function, `stopBy: end`) |
| Outgoing HTTP calls set a timeout | `requests.get(` without `timeout=`, `http.Client{}` without `Timeout`, `new HttpClient()` without `Timeout` | Ruff `S113`, `noctx` | Syntax (`not has`) |
| Resources are closed | `open(` outside `with`, `new FileInputStream` outside try-with-resources, Go `resp.Body` without `defer ... Close()` | Ruff `SIM115`, PMD `CloseResource`, `bodyclose` | Syntax |
| Context is passed through, not recreated | `context.Background()` / `context.TODO()` outside `main` and tests | `contextcheck` | Path |
| Transactions live in the service layer | `@Transactional` / `@transaction.atomic` on classes or methods in controller or repository folders | ArchUnit | Path |

## Clean Code

| Pattern | Signal | Check first | Lintability |
|---|---|---|---|
| Logging through the project's logger | `print(`, `System.out.println`, `fmt.Println`, `Console.WriteLine`, `var_dump` outside scripts and tests | Ruff `T201`, `forbidigo`, Checkstyle `RegexpSinglelineJava`, detekt `ForbiddenMethodCall` | Path |
| Environment read only in the config module | `os.environ`, `os.getenv`, `System.getenv`, `os.Getenv`, `Environment.GetEnvironmentVariable`, `getenv` outside the config folder | Ruff `TID251`, `forbidigo` | Path |
| Constructor injection over field injection | `@Autowired` / `@Inject` on fields | none | Syntax |
| No boolean flag parameters | a parameter typed `bool`/`boolean` or defaulting to `True`/`False`, or a call with literal `true`/`false` arguments | Ruff `FBT` rules | Syntax |
| Options object past N parameters | parameter count | Ruff `PLR0913`, detekt `LongParameterList`, PMD `ExcessiveParameterList` | native only (ast-grep cannot count) |
| Functions stay small | statement count, nesting, complexity | Ruff `C901`/`PLR0915`, detekt, PMD, `gocyclo`, `CA1502` | native only |
| Early return instead of else-after-return | `else` after a branch that returns | Ruff `RET505`, `revive` `early-return` | Syntax |
| No commented-out code | comments that parse as code | Ruff `ERA001` | Syntax (`kind: comment` + `regex`) |
| Layer naming (`*Service` in `service/`, `*Repository` in `repository/`) | a class declared in a layer folder whose name lacks the layer's suffix | ArchUnit, Konsist | Path |

## SOLID

### Single Responsibility

| Pattern | Signal | Check first | Lintability |
|---|---|---|---|
| Controllers hold no data access | ORM or SQL calls (`session.query`, `EntityManager`, `db.Query`) inside controller or router files | ArchUnit, import-linter | Path |
| One public type per file | count of public classes per file | Checkstyle `OuterTypeNumber`, detekt | native only |
| Controllers return DTOs, not entities | entity types in controller signatures | ArchUnit | Types |

### Open/Closed

| Pattern | Signal | Check first | Lintability |
|---|---|---|---|
| Lookup map or strategy instead of a growing `switch` / `when` / `match` / `if-elif` chain on a type code | branch count on one discriminator | Ruff `PLR0911`/`PLR0912`, detekt `CyclomaticComplexMethod` | native only |
| Extend through registration, not by editing a core module | hard to see in one file | none | Cross-file |

### Liskov Substitution

Mostly not lintable without types.
One exception: overrides that only throw "not supported" (`raise NotImplementedError` in a subclass method, `throw new UnsupportedOperationException()`, `TODO()` in Kotlin).
**Syntax**

### Interface Segregation

| Pattern | Signal | Check first | Lintability |
|---|---|---|---|
| Small interfaces | member count of interfaces, protocols and abstract classes | detekt `TooManyFunctions`, PMD `TooManyMethods` | native only |

### Dependency Inversion

| Pattern | Signal | Check first | Lintability |
|---|---|---|---|
| Layer boundaries (controller → service → repository, never backwards or skipping) | an import node whose text matches the forbidden layer, scoped by `files` to the importing layer | ArchUnit, Konsist, import-linter, `depguard`, go-arch-lint, Deptrac, NetArchTest, Packwerk | Path (direct imports), Cross-file (transitive) |
| Domain is free of frameworks | imports of `org.springframework`, `jakarta.persistence`, `django`, `fastapi`, `sqlalchemy`, `gorm`, `Microsoft.EntityFrameworkCore` in domain folders | same as above | Path |
| Depend on an injected dependency instead of `new ConcreteClient()` in business logic | constructor calls of configured classes outside configured composition roots | ArchUnit | Path |
