# Computation Patterns

Fifteen copy-paste-ready patterns. Each one shows the exact bash invocation and
the shape of the output. Pick the closest match, adapt the Wolfram code, and run.

## 1. Quick Calculation

For single-expression evaluations: arithmetic, constants, conversions.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/scripts/wolfram-eval.sh 'N[Sqrt[2], 20]'
```

Output: `1.4142135623730950488`

## 2. Symbolic Result with LaTeX

Compute symbolically, then convert to LaTeX for display.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/scripts/wolfram-eval.sh '
Module[{expr},
  expr = Integrate[x^2 * Exp[-x], x];
  ToString[TeXForm[expr]]
]'
```

Output: `e^{-x} \left(-x^2-2 x-2\right)`

Render in markdown as `$e^{-x}(-x^2-2x-2)$`.

## 3. Solve and Format

Solve an equation and present each root on its own line.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/scripts/wolfram-eval.sh '
Module[{sol},
  sol = Solve[x^3 - 6 x^2 + 11 x - 6 == 0, x];
  StringRiffle[("x = " <> ToString[x /. #]) & /@ sol, "\n"]
]'
```

Output:
```
x = 1
x = 2
x = 3
```

## 4. 2D Plot to File

Generate a plot and save it as a PNG.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/scripts/wolfram-eval.sh '
Export["/tmp/trig_plot.png",
  Plot[{Sin[x], Cos[x]}, {x, 0, 2 Pi},
    PlotLegends -> "Expressions",
    PlotTheme -> "Scientific",
    PlotLabel -> "Trigonometric Functions",
    ImageSize -> 500]]'
```

Output: `/tmp/trig_plot.png`

Use the Read tool afterward to show the image to the user.

## 5. 3D Surface

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/scripts/wolfram-eval.sh '
Export["/tmp/surface.png",
  Plot3D[Sin[x] Cos[y], {x, -Pi, Pi}, {y, -Pi, Pi},
    PlotTheme -> "Scientific",
    ColorFunction -> "TemperatureMap",
    ImageSize -> 500]]'
```

## 6. Data Analysis Pipeline

Fit a model, extract statistics, and produce a plot in one call.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/scripts/wolfram-eval.sh '
Module[{data, fit, stats},
  data = Table[{x, 2.5 x + 3 + RandomReal[{-1, 1}]}, {x, 0, 10, 0.5}];
  fit = LinearModelFit[data, x, x];
  stats = <|
    "BestFitParameters" -> fit["BestFitParameters"],
    "RSquared" -> fit["RSquared"],
    "AdjustedRSquared" -> fit["AdjustedRSquared"]|>;
  Export["/tmp/regression.png", Show[
    ListPlot[data, PlotStyle -> Red],
    Plot[fit[x], {x, 0, 10}, PlotStyle -> Blue],
    PlotLabel -> "Linear Regression", ImageSize -> 400]];
  stats
]'
```

## 7. Differential Equations

When code contains derivative apostrophes (`y'[x]`), use double quotes for the
bash argument and escape inner double quotes with `\"`. Also escape dollar signs
(`\$`) if the Wolfram code references system variables like `$VersionNumber`:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/scripts/wolfram-eval.sh "
Module[{sol},
  sol = DSolve[{y'[x] + 2 y[x] == Sin[x], y[0] == 1}, y[x], x];
  Export[\"/tmp/ode_solution.png\",
    Plot[y[x] /. sol, {x, 0, 10},
      PlotLabel -> \"ODE Solution\",
      PlotTheme -> \"Scientific\", ImageSize -> 500]];
  sol
]"
```

## 8. Matrix Operations

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/scripts/wolfram-eval.sh '
Module[{m},
  m = {{1, 2, 3}, {4, 5, 6}, {7, 8, 10}};
  StringRiffle[{
    "Det = " <> ToString[Det[m]],
    "Eigenvalues = " <> ToString[Eigenvalues[m], InputForm],
    "Inverse = " <> ToString[Inverse[m], InputForm]}, "\n"]
]'
```

## 9. Number Theory

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/scripts/wolfram-eval.sh '
Module[{n = 360},
  StringRiffle[{
    "n = " <> ToString[n],
    "Factorization: " <> ToString[FactorInteger[n]],
    "Divisors: " <> ToString[Divisors[n]],
    "Euler phi: " <> ToString[EulerPhi[n]],
    "Prime? " <> ToString[PrimeQ[n]]}, "\n"]
]'
```

## 10. Export Data as CSV or JSON

**CSV:**
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/scripts/wolfram-eval.sh '
Module[{data},
  data = Table[{x, Sin[x], Cos[x]}, {x, 0, 2 Pi, Pi/6}];
  ExportString[Prepend[data, {"x", "sin(x)", "cos(x)"}], "CSV"]
]'
```

**JSON:**
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/scripts/wolfram-eval.sh '
ExportString[<|"primes" -> Table[Prime[n], {n, 20}], "count" -> 20|>, "JSON"]'
```

## 11. Unit Conversions

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/scripts/wolfram-eval.sh '
StringRiffle[{
  "100 miles = " <> ToString[UnitConvert[Quantity[100, "Miles"], "Kilometers"]],
  "Speed of light = " <> ToString[UnitConvert[Quantity[1, "SpeedOfLight"], "Meters"/"Seconds"]],
  "1 atm = " <> ToString[UnitConvert[Quantity[1, "Atmospheres"], "Pascals"]]}, "\n"]'
```

## 12. Optimization

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/scripts/wolfram-eval.sh '
Module[{result},
  result = NMinimize[{x^4 - 3 x^2 + x, -10 <= x <= 10}, x];
  StringRiffle[{
    "Minimum value: " <> ToString[result[[1]]],
    "At: " <> ToString[result[[2]]]}, "\n"]
]' 60
```

## 13. Fourier / Laplace Transforms

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/scripts/wolfram-eval.sh '
StringRiffle[{
  "Fourier: " <> ToString[FourierTransform[Exp[-t^2], t, w]],
  "Laplace: " <> ToString[LaplaceTransform[Sin[t] Exp[-t], t, s]]}, "\n"]'
```

## 14. Probability and Distributions

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/scripts/wolfram-eval.sh '
Module[{dist, samples, stats},
  dist = MixtureDistribution[{0.3, 0.7},
    {NormalDistribution[-2, 1], NormalDistribution[3, 0.5]}];
  samples = RandomVariate[dist, 10000];
  stats = <|
    "Mean" -> Mean[samples],
    "StdDev" -> StandardDeviation[samples],
    "Skewness" -> Skewness[samples]|>;
  Export["/tmp/mixture_dist.png",
    Histogram[samples, 50, "ProbabilityDensity",
      PlotLabel -> "Mixture Distribution", ImageSize -> 500]];
  stats
]'
```

## 15. Image Processing

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/scripts/wolfram-eval.sh '
Module[{img, processed},
  img = Import["/path/to/image.png"];
  processed = ImageAdjust[ColorConvert[img, "Grayscale"]];
  Export["/tmp/processed.png", processed];
  "Dimensions: " <> ToString[ImageDimensions[processed]]
]'
```

## Anti-Patterns

**Do not pipe code into wolframscript.** Quoting breaks in non-obvious ways.
Always use the eval script, which writes code to a temp file.

**Do not omit semicolons on intermediate lines.**
```wolfram
(* wrong -- both lines print, cluttering the output *)
data = RandomReal[100, 1000]
Mean[data]

(* right -- only the final expression prints *)
data = RandomReal[100, 1000];
Mean[data]
```

**Do not run expensive code without a safety net.**
```wolfram
(* risky -- may run indefinitely *)
FindInstance[x^x == 10^6, x, Reals]

(* safer -- bounded to 15 seconds *)
TimeConstrained[FindInstance[x^x == 10^6, x, Reals], 15, "TIMEOUT"]
```
