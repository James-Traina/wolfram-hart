# wolfram-skill

A Claude Code plugin that gives Claude access to a locally installed Wolfram
Engine. When a math or science question comes up, Claude translates it to
Wolfram Language, runs it through `wolframscript`, and presents the result.
Plots get saved as PNGs and displayed inline. No special syntax or manual
triggering needed.

The full Wolfram Language is available: symbolic algebra, calculus, ODEs, linear
algebra, optimization, number theory, statistics, transforms, data analysis,
unit conversions, image processing, and graph theory.

## Prerequisites

You need the Wolfram Engine installed and activated on your machine. The engine
is free for personal and non-commercial use.

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

If you prefer not to install anything on your host:

```bash
docker run -it wolframresearch/wolframengine
```

Note that the Docker approach requires routing `wolframscript` calls into the
container, which is more involved. A native install is simpler for daily use.

### Verifying the installation

After activation, confirm everything works:

```bash
wolframscript -code '2+2'
```

Expected output: `4`. If you see a license error instead, run `wolframscript`
interactively to complete activation.

## Installing the plugin

Point Claude Code at the plugin directory:

```bash
claude --plugin-dir /path/to/wolfram-skill
```

For permanent installation, add the path to your Claude Code settings or
symlink the directory into your plugins folder.

## Usage

No special syntax is needed. Ask Claude a math question and it will use the
Wolfram Engine automatically:

- "Integrate sin(x)^2 from 0 to pi"
- "Plot x^3 - 6x^2 + 11x - 6 and mark the roots"
- "Find the eigenvalues of [[1,2],[3,4]]"
- "Solve the ODE y' + 2y = sin(x), y(0) = 1"
- "What's the Fourier transform of e^(-x^2)?"
- "Factor 123456789"
- "Convert 100 miles to kilometers"

Claude picks the right Wolfram functions, runs the code, and formats the output.

## How it works

The plugin is a single Claude Code skill with two shell scripts and three
reference files:

```
skills/wolfram/
  SKILL.md                          instructions loaded when the skill triggers
  scripts/
    wolfram-eval.sh                 executes Wolfram code through a temp file
    wolfram-check.sh                reports install status and license info
  references/
    wolfram-language-guide.md       function reference organized by domain
    common-patterns.md              15 ready-to-use computation patterns
    output-formats.md               output formatting and error detection
```

`wolfram-eval.sh` is the only interface to the engine. It writes code to a
temporary file (to avoid shell-quoting problems with Wolfram's bracket syntax),
runs `wolframscript -f <file> -print`, applies a configurable timeout, and
returns structured output with warnings separated from results.

The SKILL.md tells Claude to compute without asking for confirmation and to
batch related work into a single kernel call (the kernel takes 2-3s to start,
so fewer calls is better).

## Troubleshooting

**"wolframscript not found"** -- The engine is not installed or not in your PATH.
Follow the installation steps above. On macOS with Homebrew, make sure
`/opt/homebrew/bin` is in your PATH.

**License activation fails** -- Run `wolframscript` interactively in a terminal
(not through Claude) and sign in with your Wolfram ID. Activation only needs to
happen once.

**Computation is slow** -- The Wolfram kernel takes 2-3 seconds to start on each
call. This is normal. The skill batches related work into a single call to
minimize this overhead.

**Timeout on complex computations** -- The default timeout is 30 seconds. For
heavy numerical work, Claude will pass a longer timeout automatically. If a
computation consistently times out, the expression may need simplification or
a numerical rather than symbolic approach.

## License

MIT. See [LICENSE](LICENSE).
