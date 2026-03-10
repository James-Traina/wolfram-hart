# Changelog

All notable changes to wolfram-hart are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Versioning follows [Semantic Versioning](https://semver.org/).

## [1.0.3] - 2026-03-09

### Fixed
- `wolfram-eval.sh`, `wolfram-check.sh`: BSD `mktemp` (macOS) only randomises trailing X's, so templates like `wolfram_XXXXXX.wl` (X's before `.wl`) produced a literal filename every run, causing "File exists" collisions between consecutive test runs. Fixed by moving X's to the end of all temp file templates (dropping extensions) and stripping the trailing slash from `TMPDIR` before concatenating.

### Changed
- `wolfram-eval.sh`: unified `run_wolframscript()` to use shared `run_with_timeout()` helper; replaced stringly-typed `BOTH_FAILED="yes"/"no"` with integer `0`/`1`; replaced `$(cat file)` with `$(<file)` to avoid subprocess overhead
- `wolfram-check.sh`: extracted `trim_first_line()` helper to eliminate two duplicate sed pipelines; removed intermediate `LOCAL_OK`/`CLOUD_OK` string variables; replaced `$(cat)` with `$(<)`
- `.tests/lib/helpers.sh`: replaced `$(cat)` with `$(<)` in `run_eval`

## [1.0.2] - 2026-03-09

### Changed
- `skills/wolfram-hart/SKILL.md`: rewrote `description` to third person with 6 quoted trigger phrases for more reliable skill invocation; fixed three second-person voice lapses in body (`your training data`, `your assumption`, `You do not need to set it`)

## [1.0.1] - 2026-03-09

### Added
- `CLAUDE.md` — plugin development guide with architecture overview and testing instructions
- `.github/workflows/ci.yml` — CI pipeline: JSON validation, script permissions, test suite
- `settings.json` — plugin permissions manifest

### Changed
- Test runner: renamed `SCRIPT_DIR` → `RUNNER_DIR` to prevent collision with `helpers.sh` internal variable (was silently discovering 0 tests)
- `helpers.sh`: removed `set -euo pipefail` (sourced files must not override caller's deliberate flag choices); added comment explaining why
- All 10 test scripts: added `set -euo pipefail` and `#!/usr/bin/env bash`
- `skills/wolfram-hart/SKILL.md`: `description:` converted to `>-` folded block format
- `agents/wolfram-reviewer.md`: removed non-standard `color: yellow` field
- Commands: added `allowed-tools:` field to all 3 commands

### Removed
- `.tests/eval-framework/`: moved to `.evals/` (hidden, git-ignored)
- `.claude-plugin/marketplace.json`: catalog lives in the `science-plugins` repo

## [1.0.0] - 2026-03-04

### Added
- `/eval` command — translate natural language to Wolfram Language and execute via `wolframscript`
- `/check` command — verify `wolframscript` installation and report version/path
- `/patterns` command — display a reference index of common Wolfram computation patterns
- `wolfram-reviewer` agent — review Wolfram Language code for correctness, style, and performance
- `wolfram-hart` skill — auto-invoked on math/science/computation questions; handles symbolic algebra, calculus, plotting, statistics, unit conversion, and more
- Reference guides: `wolfram-language-guide.md`, `common-patterns.md`, `output-formats.md`
- Shell scripts with portable `wolframscript` discovery across macOS (Homebrew ARM/Intel, system, app-bundle) and Linux
