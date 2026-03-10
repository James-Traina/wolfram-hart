# wolfram-hart

A Claude Code plugin that gives Claude a real math engine. Ask a math or science question and Claude translates it to Wolfram Language, runs it through `wolframscript`, and hands back the result — symbolic answers, inline plots, numerical values, whatever the computation produces. No special syntax needed.

## Why bother?

Claude is a language model. It reconstructs answers from pattern matching, not computation. For simple things this is fine. For anything non-trivial, the reconstructed answer can be plausible-sounding and wrong.

Ask Claude (without the plugin) for the determinant of `{{2,1,0,1},{3,0,1,2},{1,2,3,0},{0,1,2,3}}`. It might say 12. The Wolfram Engine returns −6. Wolfram Language is a symbolic computation system built around mathematical correctness; the plugin routes math questions to it so you get computed answers rather than recalled ones.

## What it covers

Symbolic algebra, calculus (derivatives, integrals, limits, series), differential equations, linear algebra (eigenvalues, determinants, matrix inverses, SVD), number theory, statistics (distributions, regression), transforms (Fourier, Laplace, Z), optimization, unit conversion, plotting (2D, 3D, parametric, contour), and data export (CSV, JSON, Excel).

## How it works

The plugin installs a skill that Claude activates automatically on math and science questions:

1. Claude detects a computation request and outputs `_ᴡ wolfram_` to signal routing.
2. Claude translates the request into Wolfram Language code. Function names are capitalized (`Sin`, `Integrate`, `Solve`), arguments go in square brackets, equations use `==`.
3. Claude runs the code via `wolfram-eval.sh`, which writes the code to a temp file and passes it to `wolframscript`. The script handles timeouts, local-vs-cloud fallback, and exit codes.
4. Claude interprets the output: numbers directly, symbolic expressions as LaTeX, plot files inline via the Read tool.

The kernel takes 2–3 seconds to start. Related work gets batched into a single `Module[...]` call to avoid paying that cost multiple times.

## Prerequisites

> **Windows:** The plugin scripts are bash-only. Use WSL2 with a Linux install of the Wolfram Engine.

You need a free [Wolfram ID](https://account.wolfram.com/auth/sign-in) and one of the two options below. The free Wolfram Engine license covers personal and pre-production use; deploying Wolfram evaluation inside a product for end users requires a commercial license.

### Option A — Local Wolfram Engine

Runs entirely on your machine, works offline, no usage limits. About 1 GB to download. Better choice for heavy or repeated work.

**macOS (Homebrew)**

```bash
brew install --cask wolfram-engine
```

**macOS (manual)** — Download the installer from https://www.wolfram.com/engine/ and run it.

**Linux (Debian/Ubuntu)**

```bash
# Download the .deb from https://www.wolfram.com/engine/
sudo dpkg -i WolframEngine_*.deb
```

**Linux (RPM-based)**

```bash
sudo rpm -i WolframEngine_*.rpm
```

After installing, activate it once:

```bash
wolframscript   # sign in with your Wolfram ID when prompted
```

No environment variable needed. The plugin searches common install locations automatically (Homebrew ARM and Intel prefixes on macOS, system paths, app bundles, snap) and finds `wolframscript` wherever it lives.

### Option B — Wolfram Cloud

No download, nothing to install locally. Computation runs on Wolfram's servers. Cold starts are slower (5–10 seconds vs. 2–3 for local) and the free tier has monthly usage limits. Fine if you use the plugin occasionally or can't spare 1 GB.

**macOS**

```bash
brew install wolframscript
```

**Linux** — Download the standalone binary from https://www.wolfram.com/wolframscript/

Authenticate once:

```bash
wolframscript -authenticate
```

Then set `WOLFRAM_MODE=cloud` so the plugin skips the local attempt:

```bash
export WOLFRAM_MODE=cloud   # add to ~/.zshrc or ~/.bashrc
```

Without this, the plugin defaults to `auto`, which tries local first. If you have the binary but no local license, that means waiting out the full local timeout before the cloud fallback kicks in. `WOLFRAM_MODE=cloud` skips it.

### Verifying the setup

```
/wolfram-hart:check
```

This runs a sanity check on both local and cloud modes, prints version info, and tells you what's working and what isn't. It also recommends whether to set `WOLFRAM_MODE`.

From a terminal:

```bash
wolframscript -code '2+2'            # local — should print 4
wolframscript -cloud -code '2+2'     # cloud — should print 4
```

## Install

Inside Claude Code, run these two commands separately:

**Step 1** — add the science-plugins marketplace (one-time setup, skip if already added):

```
/plugin marketplace add James-Traina/science-plugins
```

**Step 2** — install the plugin:

```
/plugin install wolfram-hart@science-plugins
```

Restart Claude Code. The skill becomes active automatically.

> **SSH error?** Claude Code clones over SSH by default. Check with `ssh -T git@github.com`. To switch to HTTPS: `git config --global url."https://github.com/".insteadOf "git@github.com:"`

## Usage

Ask Claude a math question. The skill triggers on its own:

```
Integrate sin(x)^2 from 0 to pi
```
→ Claude runs `Integrate[Sin[x]^2, {x, 0, Pi}]` and returns `π/2`

```
Plot x^3 - 6x^2 + 11x - 6 and mark the roots
```
→ Claude generates the Wolfram Module, exports a PNG, and shows it inline

```
Find the eigenvalues of [[1,2],[3,4]]
```
→ Returns `{(5 - √33)/2, (5 + √33)/2}` in exact form

```
Solve the ODE y' + 2y = sin(x), y(0) = 1
```
→ Claude handles the derivative quoting and returns the general solution

```
What's the Fourier transform of e^(-x^2)?
```
→ Returns `e^(-π²ω²) √π` in LaTeX

```
Factor 123456789
```
→ Returns the prime factorization: `{{3, 2}, {3607, 1}, {3803, 1}}`

```
Fit a linear model to this data and show R²
```
→ Runs `LinearModelFit`, returns coefficients and R²

Numbers come back as numbers. Symbolic results get converted to LaTeX. Plots show up as inline images. Tables become markdown.

### Slash commands

**`/wolfram-hart:eval <code> [timeout]`** — Run Wolfram Language code directly, skipping the translation step. Useful when you already know the syntax.

```
/wolfram-hart:eval Integrate[Sin[x]^2, {x, 0, Pi}]
```

Append an integer ≥ 10 to override the default 30-second timeout:

```
/wolfram-hart:eval NIntegrate[Sin[x^x], {x, 0, 5}] 60
```

For code with derivative apostrophes (`y'[x]`), use double quotes:

```
/wolfram-hart:eval "DSolve[y'[x] + y[x] == Sin[x], y[x], x]"
```

**`/wolfram-hart:check`** — Show whether the Wolfram Engine is installed and configured. Prints the path to `wolframscript`, which modes are working, the engine version, and what to fix if something's broken.

```
/wolfram-hart:check
```

**`/wolfram-hart:patterns [number-or-keyword]`** — Browse 15 copy-paste computation patterns. No argument shows the index; a number or keyword shows the full pattern with expected output.

```
/wolfram-hart:patterns            # index
/wolfram-hart:patterns 7          # Differential Equations pattern in full
/wolfram-hart:patterns plot       # all patterns mentioning plotting
/wolfram-hart:patterns matrix     # matrix operations pattern
```

### Code review agent

The plugin includes a `wolfram-reviewer` agent for checking Wolfram Language code before or after running it. It catches the mistakes that most often cause silent failures: wrong capitalization, parentheses instead of square brackets, `=` instead of `==`, plots missing the `Export` wrapper, trailing semicolons suppressing the result, derivative apostrophes that need double-quote quoting.

Claude may invoke it automatically when a computation returns an unevaluated expression. You can also ask directly:

```
Can you review this Wolfram code before I run it?
```
```
Why didn't that computation work?
```

## How the output works

What the Wolfram Engine writes to stdout depends on what the expression evaluates to:

| Expression type | Output |
|---|---|
| Number | `42` or `3.14159` |
| Exact fraction | `3/8` |
| Symbolic expression | `x^3/3 + C[1]` |
| List or matrix | `{{1, 0}, {0, 1}}` |
| Association | key-value structure |
| Graphics object | `-Graphics-` (this means Export is missing) |
| File path (from Export) | `/tmp/plot.png` |

Symbolic expressions get converted to LaTeX via `ToString[TeXForm[expr]]`. Plots are wrapped in `Export["/tmp/name.png", ...]` and shown inline.

If the output equals the input, Wolfram returned the expression unevaluated. That almost always means a function name or argument type error — lowercase `sin` instead of `Sin`, or parentheses where square brackets should be.

## File structure

```
wolfram-hart/
├── .claude-plugin/
│   └── plugin.json                 plugin manifest (name, version, keywords)
├── skills/wolfram-hart/
│   ├── SKILL.md                    skill definition — trigger conditions and workflow
│   ├── scripts/
│   │   ├── wolfram-eval.sh         executes Wolfram code locally or via cloud
│   │   ├── wolfram-check.sh        checks and reports setup status
│   │   └── _find-wolframscript.sh  portable binary discovery (sourced internally)
│   └── references/
│       ├── wolfram-language-guide.md   full function reference organized by domain
│       ├── common-patterns.md          15 computation patterns with expected outputs
│       └── output-formats.md           output format control and error detection
├── commands/
│   ├── eval.md                     /wolfram-hart:eval
│   ├── check.md                    /wolfram-hart:check
│   └── patterns.md                 /wolfram-hart:patterns
└── agents/
    └── wolfram-reviewer.md         Wolfram Language code reviewer
```

The reference files in `references/` load on demand, not into every conversation. The language guide comes in when syntax is unclear, the patterns file when `/patterns` is invoked, the output-formats guide when an unexpected output type needs handling.

## Limitations

The kernel takes 2–3 seconds to cold-start on each call. The plugin batches related work into one call where possible, but you'll see a pause at the start.

Free Wolfram Cloud accounts have monthly evaluation limits. The local Engine has none.

`Entity[...]` queries (country populations, element properties, and similar) hit Wolfram's servers on first use and can add several seconds.

Image processing via `Import["/path/to/file.png"]` needs a local file. For remote images, use `Import["https://..."]`.

Interactive graphics — `Manipulate`, `Dynamic`, `Notebook` — don't work in CLI mode. All visualization goes through `Export["/tmp/name.png", ...]`.

The wrapper scripts are bash-only. Windows needs WSL2.

## Testing

102 tests across 10 files cover script mechanics, arithmetic, algebra, calculus, linear algebra, output formatting, plotting, number theory, statistics, and edge cases.

```bash
bash .tests/run-all.sh                              # full suite
bash .tests/run-all.sh .tests/tests/04-calculus.sh  # single file
```

Most tests need a working `wolframscript`. The tests in `10-edge-cases-errors.sh` stub the binary and run without one, which makes them useful for CI.

## Development

Load the plugin from a local clone:

```bash
claude --plugin-dir /path/to/wolfram-hart
```

Validate scripts and manifest before committing:

```bash
# syntax-check all bash scripts
for f in skills/wolfram-hart/scripts/*.sh; do bash -n "$f" && echo "ok: $f"; done

# validate plugin.json
python3 -c "import json, sys; json.load(open('.claude-plugin/plugin.json')); print('ok')"
```

To add a computation pattern, add a numbered section to `skills/wolfram-hart/references/common-patterns.md`. Include the exact bash invocation using `${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/scripts/wolfram-eval.sh`, the expected output shape, and any quoting notes. The `/patterns` command reads this file directly.

To add a command, create `commands/name.md` with frontmatter fields `name`, `description`, `argument-hint`, and `allowed-tools`. Commands are auto-discovered; no manifest update needed.

Bump the version in `.claude-plugin/plugin.json` whenever you change skill behavior, command logic, or reference content. Claude Code caches plugins and users won't see updates otherwise.

## Troubleshooting

**"wolframscript not found"** — Install it per the Prerequisites section. On ARM Macs, Homebrew puts it in `/opt/homebrew/bin`, not `/usr/local/bin`. Check with `echo $PATH`.

**"NOT_CONFIGURED: neither local nor cloud evaluation worked"** — `wolframscript` was found but nothing is activated. Run `/wolfram-hart:check` for specifics. Local: run `wolframscript` in a regular terminal and sign in. Cloud: run `wolframscript -authenticate`.

**Activation fails** — Run `wolframscript` in a normal terminal (not through Claude), not as root, with a stable connection. It writes a license file once and doesn't need to run again.

**Cloud authentication fails** — Run `wolframscript -authenticate`, follow the URL prompt, sign in. The terminal needs to reach `wolfram.com`.

**Local mode times out before falling back to cloud** — The local kernel is present but not licensed. Set `WOLFRAM_MODE=cloud` in your shell profile to skip the local attempt.

**Computation is slow** — The kernel cold-starts on each call (2–3 seconds, longer for cloud). Separately, if the computation itself is slow, it's usually `FindInstance` on a hard system or `NDSolve` with tight tolerances. Try relaxing the tolerances or switching to a numerical approach.

**Timeout on heavy computations** — Default is 30 seconds. Claude automatically passes longer timeouts for numerical ODEs, 3D plots, and optimization. For persistent timeouts, switch from symbolic to numerical (`NIntegrate` instead of `Integrate`, `NSolve` instead of `Solve`) or add `TimeConstrained[expr, 60, "TIMEOUT"]` inside the code.

**Graphics shows `-Graphics-` instead of an image** — The code produced a graphics object without calling `Export`. Wrap the plot: `Export["/tmp/name.png", plot]`. Most common plotting mistake.

**Plugin doesn't trigger on math questions** — Restart Claude Code after installing. If still nothing, run `/wolfram-hart:check` to confirm the plugin loaded, then try one of the trigger phrases: "what is the integral of x²" or "find the eigenvalues of this matrix".

## Updating

```bash
/plugin update wolfram-hart
```

## License

MIT. See [LICENSE](LICENSE).
