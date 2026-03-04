---
name: wolfram-hart
description: "Wolfram Engine for verified mathematical computation. Use this skill whenever the user asks you to compute, solve, integrate, differentiate, factor, invert a matrix, find eigenvalues, transform (Fourier/Laplace/Z), optimize, fit data, or work with number theory — even if you could answer from memory. Recalled math can silently contain errors; the Wolfram Engine computes and verifies (e.g. a 4×4 matrix where recalled det=6 but true det=12). Make sure to invoke this skill for: matrix operations of any size, exact symbolic integrals, ODE and recurrence solving, polynomial factoring, data regression with exact coefficients, modular arithmetic, constrained optimization, and any mention of Wolfram/Mathematica/Wolfram Language. Also use it when the user asks for an exact or verified result rather than an approximation. The only exception is truly trivial one-step problems (e.g. \"solve x²=4\") where the overhead is not warranted — for anything involving multi-step arithmetic, use this skill."
---

# Wolfram Engine

Execute exact computation through the Wolfram Engine, either locally installed
or via Wolfram Cloud. The full Wolfram Language is available: symbolic algebra,
calculus, differential equations, linear algebra, number theory, statistics,
optimization, plotting, data analysis, and image processing.

## Autonomy Rules

**Compute immediately.** When a request falls within the trigger conditions above,
translate the problem to Wolfram Language and execute it without asking the user
for confirmation. Do not ask "would you like me to use Wolfram?" or "shall I
compute this?" Just run the code and present the result.

**Compute, don't guess.** Do not answer mathematical questions from memory.
The Wolfram Engine produces verified results; your training data does not.

**Batch related work into one call.** Each invocation of `wolframscript` carries
a 2-3 second kernel startup cost. Combine related computations into a single
`Module[...]` rather than making multiple calls. For example, if the user asks
to "solve this equation and plot the roots," do both in a single script.

**Retry once on failure.** If a computation returns an unevaluated expression or
an error, consult `${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/references/wolfram-language-guide.md` to verify syntax,
adjust the code, and try once more before reporting the problem.

**Skip the pre-flight check unless something fails.** Do not run
`wolfram-check.sh` as a routine first step. Only run it if `wolfram-eval.sh`
exits with code 1 (not installed) or the output starts with `NOT_CONFIGURED`,
so the user gets actionable setup instructions.

## Workflow

### 1. Translate

Convert the user's request to Wolfram Language. Consult
`${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/references/wolfram-language-guide.md` when unsure about syntax.

Five rules that prevent the most common mistakes:

1. Function names are capitalized: `Sin`, `Solve`, `Integrate`
2. Arguments go in square brackets: `Sin[x]`, never `Sin(x)`
3. Equations use `==`: `Solve[x^2 == 4, x]`
4. Ranges and lists use braces: `{x, 0, 10}`, `{1, 2, 3}`
5. Constants are capitalized: `Pi`, `E`, `I`, `Infinity`

When a request is mathematically ambiguous (e.g., real vs. complex solutions,
degrees vs. radians), choose a reasonable interpretation and state your
assumption briefly when presenting the result.

Quick-reference mapping from natural language to Wolfram functions:

| User says | Function | Example |
|---|---|---|
| solve / find x | `Solve` | `Solve[x^2 - 4 == 0, x]` |
| solve numerically | `NSolve` / `FindRoot` | `NSolve[x^5 - x + 1 == 0, x]` |
| integrate | `Integrate` | `Integrate[Sin[x]^2, x]` |
| definite integral | `Integrate[f, {x, a, b}]` | `Integrate[x^2, {x, 0, 1}]` |
| derivative | `D` | `D[x^3 Sin[x], x]` |
| limit | `Limit` | `Limit[Sin[x]/x, x -> 0]` |
| series / Taylor | `Series` | `Series[Exp[x], {x, 0, 5}]` |
| simplify | `Simplify` / `FullSimplify` | `FullSimplify[Sin[x]^2 + Cos[x]^2]` |
| factor | `Factor` | `Factor[x^2 - 5x + 6]` |
| expand | `Expand` | `Expand[(x+1)^5]` |
| plot / graph | `Plot` | `Plot[Sin[x], {x, 0, 2Pi}]` |
| 3D surface | `Plot3D` | `Plot3D[x^2+y^2, {x,-2,2}, {y,-2,2}]` |
| eigenvalues | `Eigenvalues` | `Eigenvalues[{{1,2},{3,4}}]` |
| ODE / diff eq | `DSolve` | `DSolve[y'[x] == -y[x], y[x], x]` |
| prime factors | `FactorInteger` | `FactorInteger[360]` |
| regression / fit | `LinearModelFit` | see `references/common-patterns.md` |
| convert units | `UnitConvert` | `UnitConvert[Quantity[100,"Miles"],"Kilometers"]` |
| Fourier transform | `FourierTransform` | `FourierTransform[Exp[-x^2], x, w]` |
| optimize / minimize | `NMinimize` / `Minimize` | `NMinimize[x^4 - 3x^2 + x, x]` |
| sum of series | `Sum` | `Sum[1/n^2, {n, 1, Infinity}]` |

### 2. Build

**One-liner** for simple expressions:
```wolfram
Integrate[Sin[x]^2, {x, 0, Pi}]
```

**Module** for multi-step work (use semicolons to suppress intermediate output):
```wolfram
Module[{f, roots, plot},
  f[x_] := x^3 - 6 x^2 + 11 x - 6;
  roots = Solve[f[x] == 0, x];
  plot = Export["/tmp/cubic.png",
    Plot[f[x], {x, -1, 5}, PlotTheme -> "Scientific", ImageSize -> 500,
      Epilog -> {Red, PointSize[0.02], Point[{x, 0} /. roots]}]];
  roots
]
```

**Plots must be exported to a file.** Graphics objects have no useful text
representation. Always wrap in `Export["/tmp/descriptive_name.png", ...]` and
then use the Read tool to show the image to the user.

### 3. Execute

Run all code through the wrapper script:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/scripts/wolfram-eval.sh '<code>' [timeout]
```

The default timeout is 30 seconds. Pass a higher value as the second argument
for heavy computations (numerical ODEs, large plots, optimization):

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/scripts/wolfram-eval.sh '<code>' 120
```

**Evaluation mode.** The script respects the `WOLFRAM_MODE` environment
variable: `auto` (default, tries local then cloud), `local`, or `cloud`.
You do not need to set it — auto mode works transparently. When the user has
set `WOLFRAM_MODE=cloud`, the `-cloud` flag is added to the wolframscript
invocation and no local Engine is required. If the local kernel is present
but unlicensed, auto mode incurs the full local timeout before falling back;
in that case, `WOLFRAM_MODE=cloud` avoids the extra wait.

**Quoting.** Use single quotes around the code argument. When the code contains
derivative apostrophes (`y'[x]`), switch to double quotes and escape the inner
double quotes with `\"`:

```bash
# single quotes — normal case
bash .../wolfram-eval.sh 'Solve[x^2 == 4, x]'

# double quotes — code contains y'[x]
bash .../wolfram-eval.sh "DSolve[y'[x] + y[x] == 0, y[x], x]"
```

When using double quotes, escape dollar signs (`\$`) for any Wolfram system
variable (`$VersionNumber`, `$SystemID`, `$ProcessorCount`).

**Exit codes:** 0 = success, 1 = not installed, 2 = execution error, 3 = timeout.

### 4. Interpret and Present

| Output kind | What to do |
|---|---|
| Number | Present directly with context. |
| Symbolic expression | Render as LaTeX with `ToString[TeXForm[expr]]` for clean display. Fall back to Wolfram notation only for deeply nested procedural output. |
| List / Association | Format as a markdown table or bullet list. |
| File path (from Export) | Use the Read tool to display the image inline. |
| Unevaluated (output = input) | The function name or arguments are wrong. Check spelling and brackets. |
| Error message in output | Read the `::` message tag. Adjust code and retry once. |

For critical results, verify by substitution:
```wolfram
sol = Solve[x^2 - 5x + 6 == 0, x];
Simplify[x^2 - 5x + 6 /. sol]  (* expect {0, 0} *)
```

## Output Formats

| Goal | Wrapper | Produces |
|---|---|---|
| LaTeX | `ToString[TeXForm[expr]]` | `\frac{x^3}{3}` |
| Machine-readable | `ToString[expr, InputForm]` | `x^3/3` |
| CSV | `ExportString[data, "CSV"]` | `1,2,3\n4,5,6` |
| JSON | `ExportString[assoc, "JSON"]` | `{"key":"value"}` |
| Image file | `Export["/tmp/f.png", plot]` | file path on stdout |

## Timeouts

| Computation | Timeout |
|---|---|
| Arithmetic, simple algebra | 30 s (default) |
| Symbolic solving, series | 30-60 s |
| Numerical ODE/PDE, optimization | 60-120 s |
| 3D plots, large datasets | 60 s |

## Troubleshooting

**Not installed (exit 1).** The eval script prints setup instructions covering
both the cloud option (wolframscript binary + free account) and the local
Engine option. Relay them to the user.

**Not configured (output starts with `NOT_CONFIGURED`).** wolframscript was
found but neither local nor cloud worked. Run `wolfram-check.sh` and relay
its setup recommendations to the user.

**Graphics prints `-Graphics-`.** The code forgot to call `Export`. Wrap the
plot in `Export["/tmp/name.png", ...]`.

**Computation hangs.** Add `TimeConstrained[expr, 20, "TIMEOUT"]` inside the
Wolfram code for an inner safety net on top of the script-level timeout.

**Entity/knowledge-base queries are slow.** They fetch data over the internet on
first use. Warn the user or fall back to an approximate answer.

**Cloud evaluation is slow.** Cold-start latency for cloud kernels is higher
than local. For repeated work, consider the local Engine option.

## Reference Files

Detailed syntax and cookbook patterns, loaded on demand:

- **`${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/references/wolfram-language-guide.md`** -- Complete function reference by domain: algebra, calculus, linear algebra, statistics, plotting, data, strings, and programming constructs.
- **`${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/references/common-patterns.md`** -- 15 copy-paste-ready patterns with exact bash invocations covering the most frequent computation types.
- **`${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/references/output-formats.md`** -- How the Wolfram Engine formats different expression types, how to control the format, and how to detect errors in output.

## Scripts

- **`scripts/wolfram-eval.sh`** -- The only interface to the engine. Always use this; never call `wolframscript` directly.
- **`scripts/wolfram-check.sh`** -- Checks both local and cloud mode status. Run when `wolfram-eval.sh` exits with code 1 or produces `NOT_CONFIGURED` output.
