# wolfram-hart

A Claude Code plugin that gives Claude access to a locally installed Wolfram
Engine. When a math or science question comes up, Claude translates it to
Wolfram Language, runs it through `wolframscript`, and presents the result.
Plots get saved as PNGs and displayed inline. No special syntax needed.

Covers symbolic algebra, calculus, linear algebra, statistics, plotting, and
much more. If the Wolfram Language can do it, this plugin makes it available.

## Prerequisites

You need the Wolfram Engine installed and activated on your machine. The engine
is free for personal and non-commercial use.

> **Windows is not supported natively.** The plugin's scripts are bash-only.
> Use WSL2 with a Linux install of the Wolfram Engine if you're on Windows.

### macOS (Homebrew)

```bash
brew install --cask wolfram-engine
```

After the cask finishes, run `wolframscript` once in your terminal. It will
prompt you to sign in with a Wolfram ID (free to create) and activate the
license. The activation is a one-time step.

### macOS (manual)

Download the installer from https://www.wolfram.com/engine/ and run it. Then
open a terminal and run:

```bash
wolframscript
```

Sign in when prompted to activate the license.

### Linux (Debian/Ubuntu)

```bash
# Download the .deb from https://www.wolfram.com/engine/
sudo dpkg -i WolframEngine_*.deb
wolframscript   # activate license
```

### Linux (RPM-based)

```bash
sudo rpm -i WolframEngine_*.rpm
wolframscript   # activate license
```

### Docker

The Docker image is useful for trying Wolfram Language interactively, but this
plugin expects `wolframscript` to be on the host filesystem. Running the plugin
against a containerized engine is not currently supported.

```bash
# For standalone use only (not compatible with this plugin)
docker run -it wolframresearch/wolframengine
```

### Verifying the installation

After activation, confirm everything works:

```bash
wolframscript -code '2+2'
```

Expected output: `4`. If you see a license error instead, run `wolframscript`
interactively to complete activation.

## Installing the plugin

Tell Claude Code where the plugin lives:

```bash
claude --plugin-dir /path/to/wolfram-hart
```

For permanent installation, add the path to your Claude Code settings file
(`~/.claude/settings.json` under the `plugins` key).

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

For direct control, three slash commands are available:

```
/wolfram-hart:eval Integrate[Sin[x]^2, {x, 0, Pi}]
```

Sends raw Wolfram Language code straight to the engine. Append a timeout
(>= 10) as the last argument for heavy computations:

```
/wolfram-hart:eval NIntegrate[Sin[x^x], {x, 0, 5}] 60
```

Check your Wolfram Engine installation:

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

The plugin includes a `wolfram-reviewer` agent that checks Wolfram Language
code for common mistakes: wrong capitalization, parentheses instead of square
brackets, missing `Export` for graphics, semicolon issues, and more. It
triggers automatically when Claude detects a failed computation, or you can
ask for a review explicitly.

## How it works

The plugin has a skill, three slash commands, and a code-review agent.

```
.claude-plugin/
  plugin.json                         plugin manifest (name, version)
skills/wolfram-hart/
  SKILL.md                            instructions loaded when the skill triggers
  scripts/
    wolfram-eval.sh                   executes Wolfram code via a temp file
    wolfram-check.sh                  reports install status and license info
  references/
    wolfram-language-guide.md         function reference organized by domain
    common-patterns.md                copy-paste computation patterns
    output-formats.md                 output formatting and error detection
commands/
  eval.md                             /wolfram-hart:eval — run Wolfram code directly
  check.md                            /wolfram-hart:check — verify installation
  patterns.md                         /wolfram-hart:patterns — browse computation patterns
agents/
  wolfram-reviewer.md                 reviews Wolfram code for correctness and style
tests/
  run-tests.sh                        test runner (discovers and runs test_* functions)
  helpers.sh                          assertion library and run_eval wrapper
  batch-01.sh .. batch-10.sh          100 tests across 10 domain batches
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
computation runs without a time limit.

### Structured output

The eval script separates results from warnings. Wolfram's diagnostic messages
(like `Power::infy`) either appear inline in stdout or get routed to stderr
depending on the wolframscript version. When stderr content is present, it
appears after a `---WARNINGS---` marker so Claude can distinguish warnings
from results.

### Exit codes

| Code | Meaning |
|------|---------|
| 0 | Success. Result on stdout. |
| 1 | `wolframscript` not found (or missing argument). |
| 2 | `wolframscript` failed with no usable output. |
| 3 | Computation timed out. |

## Testing

The test suite validates 100 behaviors across 10 domain batches. Each test
calls `wolfram-eval.sh` with real Wolfram code and checks the output.

```bash
# Run all 100 tests
make test

# Run a single batch
bash tests/run-tests.sh tests/batch-01.sh

# Run specific batches
bash tests/run-tests.sh tests/batch-03.sh tests/batch-05.sh
```

The batches cover script mechanics, arithmetic, algebra, calculus, linear
algebra, output formatting, plotting, number theory, statistics, and edge
cases. Each batch takes 30-90 seconds depending on how many kernel startups
are involved (plotting batches are slower).

Tests require a working `wolframscript` installation. There are no other
dependencies.

## Development

```bash
make lint     # syntax-check all shell scripts
make check    # validate plugin.json structure
make test     # run full 100-test suite (needs wolframscript)
make help     # list all targets
```

## Troubleshooting

**"wolframscript not found"** -- The engine is not installed or not in your
PATH. Follow the installation steps above. On macOS with Homebrew, make sure
`/opt/homebrew/bin` is in your PATH.

**License activation fails** -- Run `wolframscript` interactively in a terminal
(not through Claude) and sign in with your Wolfram ID. Activation only needs
to happen once.

**Computation is slow** -- The Wolfram kernel takes a few seconds to start on
each call. This is normal. The skill batches related work into a single call
to minimize the overhead.

**Timeout on heavy computations** -- The default timeout is 30 seconds. For
numerical ODEs, 3D plots, or optimization problems, Claude will pass a longer
timeout automatically. If a computation consistently times out, it may need
simplification or a numerical rather than symbolic approach.

## License

MIT. See [LICENSE](LICENSE).
