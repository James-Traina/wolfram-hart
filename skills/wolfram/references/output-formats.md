# Output Formats

How wolframscript renders different expression types, how to control the format,
and how to recognize error conditions in the output.

## Default Behavior

When code runs through `wolfram-eval.sh`, the output is the text representation
of the final expression in the script:

| Expression type | What stdout looks like | Example |
|---|---|---|
| Integer or real | Plain number | `42`, `3.14159` |
| Symbolic | Text math notation | `x/2 - Sin[2*x]/4` |
| List | Curly braces | `{1, 4, 9, 16, 25}` |
| Nested list (matrix) | Nested curly braces | `{{1, 0}, {0, 1}}` |
| Association | Angle-bracket notation | `<\|a -> 1, b -> 2\|>` |
| Boolean | Capitalized word | `True` or `False` |
| String | Bare text (no quotes) | `hello world` |
| Graphics object | Opaque tag | `-Graphics-` |
| Unrecognized function | Echoed back verbatim | `Foo[x]` |
| Error with result | Warning lines then result | `Power::infy: ... ComplexInfinity` |

## Controlling the Format

### LaTeX

```wolfram
ToString[TeXForm[Integrate[1/(1 + x^2), x]]]
```
Produces: `\tan ^{-1}(x)`

Present to the user as inline math: `$\tan^{-1}(x)$`

### Machine-Readable (InputForm)

```wolfram
ToString[Solve[x^2 == 2, x], InputForm]
```
Produces: `{{x -> -Sqrt[2]}, {x -> Sqrt[2]}}`

Useful when the result will be fed into another computation or parsed by code.

### Structured Data

**JSON:**
```wolfram
ExportString[<|"roots" -> {1, 2, 3}|>, "JSON"]
```

**CSV:**
```wolfram
ExportString[Prepend[Table[{n, Prime[n]}, {n, 10}], {"n", "p(n)"}], "CSV"]
```

### Human-Readable Multi-Line

Use `StringRiffle` with `"\n"` as the separator:

```wolfram
StringRiffle[{
  "Result: " <> ToString[N[Pi, 30]],
  "Digits: 30",
  "Time: " <> ToString[AbsoluteTiming[N[Pi, 10000]][[1]]] <> " s"
}, "\n"]
```

## File Export for Graphics

Any expression that produces a graphics object (`Plot`, `Plot3D`, `ListPlot`,
`Histogram`, etc.) must be saved to a file. Graphics objects have no usable text
form.

```wolfram
Export["/tmp/plot.png", Plot[Sin[x], {x, 0, 2 Pi}], ImageSize -> 500]
```

### Format Choice

| Format | Best for |
|---|---|
| PNG | Plots and charts (good quality, reasonable size) |
| SVG | Diagrams and line art (vector, scales without blur) |
| PDF | Publication-quality output |

Avoid JPEG for plots; lossy compression creates visible artifacts on line art.

### Image Sizing

| Scenario | `ImageSize` value |
|---|---|
| Standard plot | `400` or `500` |
| Wide (e.g., time series) | `{600, 300}` |
| High resolution | `800` |
| Thumbnail | `200` |

## Recognizing Errors

### Warning Messages

Wolfram prints warning messages inline with the output. They follow the pattern
`SymbolName::tag: message text`. The actual result appears after all warnings.

```
                                 1
Power::infy: Infinite expression - encountered.
                                 0
ComplexInfinity
```

In this example the result is `ComplexInfinity`; the lines above it are the
warning. The eval script separates these with a `---WARNINGS---` marker when
they are written to stderr.

### Unevaluated Expressions

When a function name is misspelled or the arguments are wrong, Wolfram returns
the expression unchanged:

```wolfram
Solvee[x^2 == 4, x]   (* typo: returns Solvee[x^2 == 4, x] *)
```

Detection rule: if the output is structurally identical to the input, the
computation did not evaluate. Check spelling and argument structure.

### Clean Error Handling

Use `Check` to catch messages and return a controlled fallback:

```wolfram
Check[1/0, "ERROR: division by zero"]
```

Use `Quiet` to suppress non-critical messages when they would clutter output:

```wolfram
Quiet[expr]                    suppress all messages
Quiet[expr, {Power::infy}]    suppress a specific message
```
