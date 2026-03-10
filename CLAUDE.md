# wolfram-hart Plugin

Gives Claude a real math engine. Translates math and science questions to Wolfram Language, executes them via `wolframscript`, and returns exact results — symbolic algebra, calculus, plotting, statistics, and more.

## Architecture

**Skill triggers → Eval script → wolframscript → Result back to Claude**

The `wolfram-hart` skill auto-invokes on math/science questions. It calls `wolfram-eval.sh`, which discovers `wolframscript` via `_find-wolframscript.sh` and runs the generated Wolfram Language expression. Plots are exported as PNGs.

## Component Inventory

| Type | Name | Purpose |
|------|------|---------|
| Skill | `wolfram-hart` | Auto-invoked on math/science/computation questions |
| Command | `/eval` | Execute Wolfram Language code directly |
| Command | `/check` | Verify wolframscript installation and report version/path |
| Command | `/patterns` | Browse the 15 copy-paste computation patterns |
| Agent | `wolfram-reviewer` | Review Wolfram Language code for correctness, style, and performance |

## File Structure

```
.claude-plugin/plugin.json    Plugin manifest
skills/wolfram-hart/
  SKILL.md                    Skill definition and trigger description
  scripts/
    wolfram-eval.sh           Main evaluation script
    wolfram-check.sh          Setup verification script
    _find-wolframscript.sh    Sourced discovery helper (not executed directly)
  references/
    wolfram-language-guide.md Wolfram Language reference
    common-patterns.md        15 numbered computation patterns
    output-formats.md         Output formatting guide
commands/
  eval.md                     /eval command
  check.md                    /check command
  patterns.md                 /patterns command
agents/
  wolfram-reviewer.md         Wolfram Language code reviewer
settings.json                 Plugin permissions
```

## Testing

Run: `bash .tests/run-all.sh`

Selective: `bash .tests/run-all.sh .tests/tests/04-calculus.sh` runs a single test file.

Eval runs are gitignored under `.evals/`.

## Evals

Automated quality evals live in `.evals/`. Run manually — not part of CI.

## Critical Invariants

- **`_find-wolframscript.sh` is sourced, not executed** — it has no `set -euo pipefail` and no execute permission by design. It is always sourced with `. "$DIR/_find-wolframscript.sh"`.
- **WOLFRAM_MODE env var** controls local vs cloud evaluation: `local`, `cloud`, or `auto` (default).
- **Plots must be exported** — any Wolfram expression producing graphics must use `Export["/tmp/plot.png", ...]` not `Show[]`.
- **Version bumping required for updates** — Claude Code caches plugins; users only get updates if `version` in `.claude-plugin/plugin.json` is incremented.
- **Flat repo structure** — `.claude-plugin/plugin.json` must stay at repo root.
- **Test runner omits `-e`** — `.tests/run-all.sh` uses `set -uo pipefail` (not `-e`) deliberately so test functions can return non-zero without aborting the runner.

## Development

### Adding a computation pattern
Add a numbered entry to `skills/wolfram-hart/references/common-patterns.md`. The `/patterns` command reads this file.

### Adding a command
1. Create `commands/name.md` with frontmatter: `name`, `description`, `argument-hint`, `allowed-tools`
2. No plugin.json update needed — commands are auto-discovered

### Adding an agent
1. Create `agents/name.md` with frontmatter: `name`, `description` (>- with examples), `model`, `tools` (YAML list)
2. No plugin.json update needed

## Domain Keywords

Algebra, Calculus, Computation, Differential Equations, Eigenvalues, Factoring, Fourier Transform, Integration, Inverse Matrix, Laplace Transform, Linear Algebra, Mathematica, Mathematical Computing, Matrix Operations, Number Theory, Numerical Analysis, Optimization, Plotting, Scientific Computing, Solving Equations, Statistics, Symbolic Computation, Unit Conversion, Wolfram, Wolfram Engine, Wolfram Language, Z-Transform.
