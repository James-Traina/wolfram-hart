# wolfram-hart

A Claude Code plugin that gives Claude access to the Wolfram Engine. When a
math or science question comes up, Claude translates it to Wolfram Language,
runs it through `wolframscript`, and presents the result. Plots get saved as
PNGs and displayed inline. No special syntax needed.

Covers symbolic algebra, calculus, linear algebra, statistics, plotting, and
much more. If the Wolfram Language can do it, this plugin makes it available.

## Installing from GitHub

```
/plugin marketplace add James-Traina/wolfram-hart
/plugin install wolfram-hart@James-Traina-wolfram-hart
```

Then restart Claude Code. That's it — the plugin is active.

---

## Prerequisites

> **Windows is not supported natively.** The plugin's scripts are bash-only.
> Use WSL2 with a Linux install if you're on Windows.

Two options. Pick whichever fits your situation:

### Option A — Cloud evaluation (fastest setup)

No Engine download. Needs internet. A free Wolfram account is required.

```bash
# macOS
brew install wolframscript

# Linux — download the standalone binary from:
# https://www.wolfram.com/wolframscript/
```

After installing, authenticate once:

```bash
wolframscript -authenticate
```

Then tell the plugin to use cloud mode:

```bash
export WOLFRAM_MODE=cloud   # add this to ~/.zshrc or ~/.bashrc
```

### Option B — Local Engine (offline-capable)

Faster for repeated use. About 1 GB download. Free for personal and
non-commercial use.

**macOS (Homebrew)**

```bash
brew install --cask wolfram-engine
```

**macOS (manual)** — download from https://www.wolfram.com/engine/ and run
the installer.

**Linux (Debian/Ubuntu)**

```bash
# Download the .deb from https://www.wolfram.com/engine/
sudo dpkg -i WolframEngine_*.deb
```

**Linux (RPM-based)**

```bash
sudo rpm -i WolframEngine_*.rpm
```

After installing, activate once:

```bash
wolframscript   # sign in with a free Wolfram ID when prompted
```

No environment variable needed. The plugin uses local mode automatically.

### Verifying the setup

```bash
/wolfram-hart:check
```

Or from the terminal:

```bash
wolframscript -code '2+2'            # local mode
wolframscript -cloud -code '2+2'     # cloud mode
```

Both should output `4`.

## Local / development install

To load the plugin from a local clone:

```bash
claude --plugin-dir /path/to/wolfram-hart
```

For a permanent local install, add the path to `~/.claude/settings.json` under
the `plugins` key.

## Usage

Ask Claude a math question and it will call the Wolfram Engine on its own:

- "Integrate sin(x)^2 from 0 to pi"
- "Plot x^3 - 6x^2 + 11x - 6 and mark the roots"
- "Find the eigenvalues of [[1,2],[3,4]]"
- "Solve the ODE y' + 2y = sin(x), y(0) = 1"
- "What's the Fourier transform of e^(-x^2)?"
- "Factor 123456789"
- "Convert 100 miles to kilometers"

Claude translates the question to Wolfram Language, calls `wolfram-eval.sh`,
reads the output, and presents it in whatever format makes sense (plain text,
LaTeX, or an inline image for plots).

### Slash commands

Three slash commands give you direct access:

```
/wolfram-hart:eval Integrate[Sin[x]^2, {x, 0, Pi}]
```

This sends raw Wolfram code to the engine. Append a timeout (>= 10) for
heavy computations:

```
/wolfram-hart:eval NIntegrate[Sin[x^x], {x, 0, 5}] 60
```

Check whether the Wolfram Engine is installed and licensed:

```
/wolfram-hart:check
```

Browse the 15 built-in computation patterns:

```
/wolfram-hart:patterns            # show index
/wolfram-hart:patterns 7          # show pattern #7 (Differential Equations)
/wolfram-hart:patterns plot       # show all plotting patterns
```

### Code review agent

The plugin also has a `wolfram-reviewer` agent that catches common Wolfram
Language mistakes — wrong capitalization, parentheses instead of square
brackets, missing `Export` on graphics, semicolon problems. Claude may invoke
it when a computation fails, or you can ask for a review yourself.

## How it works

```
.claude-plugin/
  plugin.json                         plugin manifest (name, version)
skills/wolfram-hart/
  SKILL.md                            instructions loaded when the skill triggers
  scripts/
    wolfram-eval.sh                   executes Wolfram code (local or cloud)
    wolfram-check.sh                  reports setup status for both modes
    _find-wolframscript.sh            shared binary discovery (sourced internally)
  references/
    wolfram-language-guide.md         function reference organized by domain
    common-patterns.md                copy-paste computation patterns
    output-formats.md                 output formatting and error detection
commands/
  eval.md                             /wolfram-hart:eval — run Wolfram code directly
  check.md                            /wolfram-hart:check — verify setup
  patterns.md                         /wolfram-hart:patterns — browse computation patterns
agents/
  wolfram-reviewer.md                 reviews Wolfram code for correctness and style
tests/
  run-tests.sh                        test runner (discovers and runs test_* functions)
  helpers.sh                          assertion library and run_eval wrapper
  batch-01.sh .. batch-10.sh          100 tests across 10 domain batches
LICENSE                               MIT license
```

### Why a temp file?

Wolfram Language uses `[`, `]`, `{`, `}`, `'`, and `$` constantly. Every one of
those characters means something to the shell. Instead of fighting quoting
issues, `wolfram-eval.sh` writes the code to a temporary `.wl` file, passes it
to `wolframscript -f`, and cleans up afterward. This makes the full Wolfram
Language available without any escaping workarounds.

### Timeouts

`wolframscript` can hang on bad inputs or computations that blow up. The eval
script wraps the call in `timeout` (or `gtimeout` on macOS) with a configurable
limit. The default is 30 seconds; Claude passes longer timeouts automatically
for heavy numerical work. If neither `timeout` nor `gtimeout` is available, the
computation runs without a time limit. On macOS, `brew install coreutils`
provides `gtimeout`.

### Structured output

The eval script separates results from warnings. Wolfram's diagnostic messages
(like `Power::infy`) either appear inline in stdout or get routed to stderr
depending on the wolframscript version. When stderr content is present, it
appears after a `---WARNINGS---` marker so Claude can distinguish warnings
from results.

Sentinel prefixes in the output indicate specific failure modes:

- `NOT_INSTALLED:` — wolframscript binary not found on the system.
- `NOT_CONFIGURED:` — wolframscript found but neither local nor cloud works.
- `TIMEOUT:` — computation exceeded the time limit.

These sentinels appear at the start of stdout so tooling can match them
reliably without parsing free-text error messages.

### Exit codes

| Code | Meaning |
|------|---------|
| 0 | Success. Result on stdout. |
| 1 | `wolframscript` not found (or missing argument). |
| 2 | `wolframscript` failed with no usable output. |
| 3 | Computation timed out. |

## Testing

The test suite validates 102 behaviors across 10 domain batches. Each test
calls `wolfram-eval.sh` with real Wolfram code and checks the output.

```bash
# Run all tests
bash tests/run-tests.sh tests/batch-*.sh

# Run a single batch
bash tests/run-tests.sh tests/batch-01.sh

# Run specific batches
bash tests/run-tests.sh tests/batch-03.sh tests/batch-05.sh
```

The batches cover script mechanics, arithmetic, algebra, calculus, linear
algebra, output formatting, plotting, number theory, statistics, and edge
cases (including exit code 1 and 2 error paths). Each batch takes 30-90
seconds depending on how many kernel startups are involved (plotting batches
are slower). The exit code tests in batch-10 use stubs and run without a
working Wolfram installation.

Tests require a working `wolframscript` installation for most batches. There
are no other dependencies.

## Development

```bash
# Syntax-check all shell scripts
for f in skills/wolfram-hart/scripts/*.sh; do bash -n "$f" && echo "ok: $f"; done

# Validate plugin.json
python3 -c "import json, sys; json.load(open('.claude-plugin/plugin.json')); print('plugin.json ok')"

# Run full test suite (needs wolframscript)
bash tests/run-tests.sh tests/batch-*.sh
```

## Troubleshooting

**"wolframscript not found"** -- Install it following the Prerequisites above.
On macOS with Homebrew, make sure `/opt/homebrew/bin` is in your PATH.

**"NOT_CONFIGURED: neither local nor cloud evaluation worked"** -- wolframscript
is installed but not set up. Run `/wolfram-hart:check` and follow its
recommendations. For local mode, run `wolframscript` interactively to activate
the license. For cloud mode, run `wolframscript -authenticate`.

**License activation fails** -- Run `wolframscript` interactively in a terminal
(not through Claude) and sign in with your Wolfram ID. Activation only needs
to happen once.

**Cloud authentication fails** -- Run `wolframscript -authenticate` in a
terminal and follow the prompts. Once configured, cloud evaluation persists
across sessions.

**Computation is slow** -- The Wolfram kernel takes a few seconds to start on
each call (longer for cloud). The skill batches related work into a single call
to minimize the overhead.

**Timeout on heavy computations** -- The default timeout is 30 seconds. For
numerical ODEs, 3D plots, or optimization problems, Claude will pass a longer
timeout automatically. If a computation consistently times out, it may need
simplification or a numerical rather than symbolic approach.

## License

MIT. See [LICENSE](LICENSE).
