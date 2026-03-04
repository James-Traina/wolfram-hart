# wolfram-hart

A Claude Code plugin that gives Claude access to the Wolfram Engine. When a
math or science question comes up, Claude translates it to Wolfram Language,
runs it through `wolframscript`, and presents the result. Plots get saved as
PNGs and displayed inline. No special syntax needed.

Covers symbolic algebra, calculus, linear algebra, statistics, plotting, and
much more. If the Wolfram Language can do it, this plugin makes it available.

## Prerequisites

> **Windows:** The plugin scripts are bash-only. Use WSL2 with a Linux install.

You need a free [Wolfram ID](https://account.wolfram.com/auth/sign-in) for
either option below. The free Wolfram Engine license covers personal and
pre-production use. It does not cover deploying Wolfram evaluation inside a
product for end users — that requires a paid license. For personal use and
experimenting, the free tier is fine.

### Option A — Local Engine

Faster, works offline, no usage limits. About 1 GB download.

**macOS (Homebrew)**

```bash
brew install --cask wolfram-engine
```

**macOS (manual)** — download from https://www.wolfram.com/engine/ and run the
installer.

**Linux (Debian/Ubuntu)**

```bash
# Download the .deb from https://www.wolfram.com/engine/
sudo dpkg -i WolframEngine_*.deb
```

**Linux (RPM-based)**

```bash
sudo rpm -i WolframEngine_*.rpm
```

Activate once after installing:

```bash
wolframscript   # sign in with your Wolfram ID when prompted
```

No environment variable needed — the plugin detects the local Engine
automatically.

### Option B — Cloud evaluation

No download. Needs internet and a free Wolfram account. Cold starts are slower
(5-10 seconds) and the free cloud tier has monthly usage limits.

**macOS**

```bash
brew install wolframscript
```

**Linux** — download the standalone binary from
https://www.wolfram.com/wolframscript/

Authenticate once:

```bash
wolframscript -authenticate
```

Then tell the plugin to use cloud mode:

```bash
export WOLFRAM_MODE=cloud   # add this to ~/.zshrc or ~/.bashrc
```

### Verifying the setup

```
/wolfram-hart:check
```

Or from a terminal:

```bash
wolframscript -code '2+2'            # local
wolframscript -cloud -code '2+2'     # cloud
```

Both should print `4`.

## Install

Inside Claude Code, run each command **separately**:

**Step 1** — add this repo as a plugin source:

```
/plugin marketplace add James-Traina/wolfram-hart
```

**Step 2** — install the plugin:

```
/plugin install wolfram-hart@James-Traina-wolfram-hart
```

Restart Claude Code. That's it.

> **SSH error?** Claude Code clones over SSH by default. Check with
> `ssh -T git@github.com`. To switch to HTTPS instead:
> `git config --global url."https://github.com/".insteadOf "git@github.com:"`

## Usage

Ask Claude a math question and it will call the Wolfram Engine on its own:

- "Integrate sin(x)^2 from 0 to pi"
- "Plot x^3 - 6x^2 + 11x - 6 and mark the roots"
- "Find the eigenvalues of [[1,2],[3,4]]"
- "Solve the ODE y' + 2y = sin(x), y(0) = 1"
- "What's the Fourier transform of e^(-x^2)?"
- "Factor 123456789"
- "Convert 100 miles to kilometers"

Claude translates the question to Wolfram Language, runs it, and presents the
result as plain text, LaTeX, or an inline image for plots.

### Slash commands

Run Wolfram code directly:

```
/wolfram-hart:eval Integrate[Sin[x]^2, {x, 0, Pi}]
```

Append a timeout (seconds) for heavy computations:

```
/wolfram-hart:eval NIntegrate[Sin[x^x], {x, 0, 5}] 60
```

Check whether the Wolfram Engine is installed and configured:

```
/wolfram-hart:check
```

Browse the 15 built-in computation patterns:

```
/wolfram-hart:patterns            # index
/wolfram-hart:patterns 7          # pattern #7 (Differential Equations)
/wolfram-hart:patterns plot       # all plotting patterns
```

### Code review agent

The plugin includes a `wolfram-reviewer` agent that catches common Wolfram
Language mistakes: wrong capitalization, parentheses instead of square
brackets, missing `Export` on graphics, semicolon issues. Claude may invoke
it when a computation fails, or you can ask for a review manually.

## How it works

```
.claude-plugin/
  plugin.json                         plugin manifest
  marketplace.json                    marketplace catalog
skills/wolfram-hart/
  SKILL.md                            instructions Claude follows
  scripts/
    wolfram-eval.sh                   runs Wolfram code (local or cloud)
    wolfram-check.sh                  reports setup status
    _find-wolframscript.sh            binary discovery (sourced internally)
  references/
    wolfram-language-guide.md         function reference by domain
    common-patterns.md                15 copy-paste computation patterns
    output-formats.md                 output formatting and error detection
commands/
  eval.md                             /wolfram-hart:eval
  check.md                            /wolfram-hart:check
  patterns.md                         /wolfram-hart:patterns
agents/
  wolfram-reviewer.md                 Wolfram code reviewer
tests/
  run-tests.sh                        test runner
  helpers.sh                          assertion library
  batch-01.sh .. batch-10.sh          102 tests across 10 domain batches
```

## Testing

The test suite validates 102 behaviors across 10 domain batches.

```bash
bash tests/run-tests.sh tests/batch-*.sh    # all tests
bash tests/run-tests.sh tests/batch-01.sh   # single batch
```

Batches cover: script mechanics, arithmetic, algebra, calculus, linear algebra,
output formatting, plotting, number theory, statistics, and edge cases. Most
batches need a working `wolframscript` installation; the exit-code tests in
batch-10 use stubs and run without one.

## Development

Load the plugin from a local clone (useful when modifying the plugin itself):

```bash
claude --plugin-dir /path/to/wolfram-hart
```

Syntax-check all scripts and validate the manifest:

```bash
for f in skills/wolfram-hart/scripts/*.sh; do bash -n "$f" && echo "ok: $f"; done
python3 -c "import json, sys; json.load(open('.claude-plugin/plugin.json')); print('ok')"
```

## Troubleshooting

**"wolframscript not found"** — Install it per the Prerequisites above. On
macOS with Homebrew, make sure `/opt/homebrew/bin` is in your PATH.

**"NOT_CONFIGURED: neither local nor cloud evaluation worked"** —
wolframscript is installed but not activated. Run `/wolfram-hart:check` for
specific recommendations. For local mode, run `wolframscript` interactively to
sign in. For cloud, run `wolframscript -authenticate`.

**License activation fails** — Run `wolframscript` in a normal terminal
(not through Claude) and sign in with your Wolfram ID. Only needed once.

**Cloud authentication fails** — Run `wolframscript -authenticate` in a
terminal and follow the prompts.

**Computation is slow** — The Wolfram kernel takes 2-3 seconds to start each
call (longer for cloud). The plugin batches related work into a single call to
reduce overhead.

**Timeout on heavy computations** — Default is 30 seconds. Claude
automatically passes longer timeouts for numerical ODEs, 3D plots, and
optimization. If a computation consistently times out, try a numerical rather
than symbolic approach.

## License

MIT. See [LICENSE](LICENSE).
