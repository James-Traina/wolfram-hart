# Wolfram Language Reference

A focused reference of the syntax and functions that come up most often when
translating natural-language math requests into Wolfram Language code. Emphasis
is on patterns that differ from standard mathematical notation or that are easy
to get wrong.

## Syntax Essentials

### Brackets

Wolfram Language uses four kinds of brackets, each with a distinct meaning:

| Bracket | Purpose | Example |
|---|---|---|
| `[...]` | Function application | `Sin[x]`, `Solve[expr, x]` |
| `{...}` | Lists (vectors, ranges, sets) | `{1, 2, 3}`, `{x, 0, 10}` |
| `[[...]]` | Part extraction (indexing) | `list[[3]]` third element |
| `(...)` | Grouping only | `(a + b) * c` |

Parentheses are never used for function calls. `Sin(x)` does not call `Sin`.

### Operators

```
==    equation (mathematical equality; used in Solve, DSolve)
=     immediate assignment         x = 5
:=    delayed assignment           f[x_] := x^2
->    rule                         x -> 3
/.    apply rule                   expr /. x -> 3
//    postfix function             expr // Simplify
@     prefix function              Simplify @ expr
/@    map over list                f /@ {1,2,3}
<>    string join                  "a" <> "b"
^     power                        x^2
*     multiplication (or space)    2*x  or  2 x
.     dot product / matrix mult    m . v
&&    logical AND       ||    logical OR       !    logical NOT
```

### Pattern Matching

```
_          any single expression          f[x_] := x^2
__         one or more expressions
___        zero or more expressions
x_Integer  constrained to Integer head
/;         condition guard                f[x_] /; x > 0 := Sqrt[x]
```

### Strings

```
"hello"                         literal string
"a" <> "b"                      concatenation
ToString[expr]                  convert expression to string
ToString[expr, InputForm]       machine-readable string
ToExpression["x^2"]             parse string to expression
```

## Functions by Domain

### Algebra and Equations

```
Solve[x^2 - 5x + 6 == 0, x]              exact symbolic solutions
NSolve[x^5 - x + 1 == 0, x]              numerical solutions
FindRoot[Cos[x] == x, {x, 1}]            single numerical root near guess
Reduce[x^2 + y^2 < 1 && x > 0, {x, y}]  reduce inequalities
Simplify[expr]                            simplify
FullSimplify[expr]                        more aggressive simplification
Simplify[expr, Assumptions -> x > 0]     simplify with assumption
FullSimplify[Sqrt[x^2], Assumptions -> x > 0]  gives x (not Abs[x])
Factor[x^2 - 5x + 6]                     factor polynomial
Expand[(x+1)^5]                           expand
Apart[1/(x^2 - 1)]                        partial fractions
Together[1/x + 1/y]                       common denominator
```

**Note on Assumptions:** Without assumptions, `Simplify[Sqrt[x^2]]` returns `Abs[x]` (correct for all reals). Add `Assumptions -> x > 0` to get `x`. This matters for integrals and inequalities involving square roots or absolute values.

### Calculus

```
D[f[x], x]                              first derivative
D[f[x], {x, n}]                         nth derivative
D[f[x,y], x, y]                         mixed partial derivative
Integrate[f[x], x]                       indefinite integral
Integrate[f[x], {x, a, b}]              definite integral
Integrate[f[x,y], {x,a,b}, {y,c,d}]    double integral
Limit[Sin[x]/x, x -> 0]                 limit
Limit[f[x], x -> a, Direction -> -1]    right-sided limit (from above)
Limit[f[x], x -> a, Direction ->  1]    left-sided limit (from below)
Series[Exp[x], {x, 0, 5}]              Taylor series to order 5
Normal[%]                                series -> polynomial
Sum[1/n^2, {n, 1, Infinity}]            infinite sum
Product[k, {k, 1, n}]                   product
DSolve[y'[x] + y[x] == Sin[x], y[x], x]         symbolic ODE
DSolve[{y'[x] == -y[x], y[0] == 1}, y[x], x]    initial-value problem
NDSolve[{y'[x] == -y[x]^2, y[0] == 1}, y, {x, 0, 10}]  numerical ODE
```

### Linear Algebra

```
m = {{1,2},{3,4}}                matrix literal
Inverse[m]                       matrix inverse
Det[m]                           determinant
Eigenvalues[m]                   eigenvalues
Eigenvectors[m]                  eigenvectors
MatrixRank[m]                    rank
Transpose[m]                     transpose
m . v                            matrix-vector product
IdentityMatrix[3]                3x3 identity matrix
LinearSolve[m, b]               solve m.x = b
NullSpace[m]                     null space basis
CharacteristicPolynomial[m, x]  characteristic polynomial
SingularValueDecomposition[m]   SVD
```

### Statistics and Probability

```
Mean[data]                                     arithmetic mean
Median[data]                                   median
StandardDeviation[data]                        standard deviation
Variance[data]                                 variance
Quantile[data, 0.95]                           95th percentile
Correlation[data1, data2]                      Pearson correlation
LinearModelFit[data, x, x]                    simple linear regression
NonlinearModelFit[data, a Exp[b x], {a,b}, x] nonlinear fit
NormalDistribution[mu, sigma]                  define a distribution
PDF[NormalDistribution[0,1], x]               probability density
CDF[NormalDistribution[0,1], 1.96]            cumulative distribution
RandomVariate[NormalDistribution[], 1000]      draw 1000 samples
Histogram[data]                                histogram (graphics)
```

### Number Theory

```
FactorInteger[60]           prime factorization: {{2,2},{3,1},{5,1}}
PrimeQ[17]                  primality test
Prime[100]                  100th prime
NextPrime[100]              next prime after 100
GCD[12, 18]                 greatest common divisor
LCM[12, 18]                 least common multiple
Mod[17, 5]                  modular arithmetic
PowerMod[2, 100, 97]        modular exponentiation
EulerPhi[100]               Euler totient
```

### Transforms

```
FourierTransform[Exp[-x^2], x, w]            symbolic Fourier
InverseFourierTransform[expr, w, x]           inverse Fourier
LaplaceTransform[Sin[t], t, s]                Laplace
InverseLaplaceTransform[1/(s^2+1), s, t]      inverse Laplace
```

### Optimization

```
Minimize[x^4 - 3x^2 + x, x]                  exact symbolic minimum
NMinimize[f[x,y], {x,y}]                      numerical minimization
NMaximize[f[x,y], {x,y}]                      numerical maximization
FindMinimum[f[x], {x, x0}]                    local minimum near x0
LinearProgramming[c, m, b]                     linear programming
```

### Plotting and Visualization

```
(* 2D *)
Plot[Sin[x], {x, 0, 2 Pi}]
Plot[{Sin[x], Cos[x]}, {x, 0, 2 Pi}, PlotLegends -> "Expressions"]
ListPlot[data]
ListLinePlot[data]
ParametricPlot[{Cos[t], Sin[t]}, {t, 0, 2 Pi}]

(* 3D *)
Plot3D[Sin[x] Cos[y], {x, -Pi, Pi}, {y, -Pi, Pi}]
ContourPlot[x^2 + y^2, {x, -2, 2}, {y, -2, 2}]
ParametricPlot3D[{Cos[t], Sin[t], t/10}, {t, 0, 20}]

(* Useful options *)
PlotTheme -> "Scientific"       clean academic style
PlotLabel -> "Title"            title text
AxesLabel -> {"x", "y"}         axis labels
PlotRange -> {0, 1}             constrain y-range
ImageSize -> 500                output width in pixels
PlotStyle -> {Red, Blue}        line colors
Frame -> True                   framed axes
GridLines -> Automatic          background grid
PlotLegends -> "Expressions"    auto legend
```

### Data, Units, and Knowledge Base

```
Entity["Country", "France"]["Population"]         built-in knowledge
Entity["Element", "Gold"]["AtomicMass"]
EntityValue[Entity["Country", "UnitedStates"], "GDP"]
UnitConvert[Quantity[100, "Miles"], "Kilometers"]  unit conversion
Quantity[9.8, "Meters"/"Seconds"^2]                define a quantity
```

Note: `Entity` queries fetch data over the internet on first use and can be slow.

### String and Text Processing

```
StringLength["hello"]
StringReplace["hello world", "world" -> "earth"]
StringCases["abc123def", DigitCharacter ..]
StringSplit["a,b,c", ","]
StringMatchQ["test123", __ ~~ DigitCharacter ..]
```

### Programming Constructs

```
(* local variables *)
Module[{x = 5, y},
  y = x^2;
  y + 1
]

(* list generation *)
Table[i^2, {i, 1, 10}]
Table[{i, j}, {i, 3}, {j, 3}]

(* functional *)
Map[f, {1,2,3}]                    {f[1], f[2], f[3]}
Select[{1,2,3,4,5}, EvenQ]        {2, 4}
Fold[Plus, 0, {1,2,3}]            6
NestList[f, x, 3]                 {x, f[x], f[f[x]], f[f[f[x]]]}

(* conditionals *)
If[x > 0, "positive", "non-positive"]
Which[x < 0, "neg", x == 0, "zero", True, "pos"]
```

## Output Formatting

```
ToString[TeXForm[expr]]           LaTeX string
ToString[expr, InputForm]         machine-readable Wolfram syntax
ExportString[data, "CSV"]         CSV string
ExportString[data, "JSON"]        JSON string
ExportString[data, "TSV"]         tab-separated string

Export["/path/file.png", plot]    raster image
Export["/path/file.pdf", plot]    PDF vector
Export["/path/file.svg", plot]    SVG vector
Export["/path/file.csv", data]    CSV file
Export["/path/file.xlsx", data]   Excel file
```

## Error Handling

```
Check[1/0, "ERROR: division by zero"]          catch messages
Quiet[expr]                                     suppress all warnings
Quiet[expr, {Power::infy}]                      suppress specific warning
TimeConstrained[expr, 10, "TIMEOUT"]            bound computation time
MemoryConstrained[expr, 10^9, "OOM"]            bound memory use
If[NumericQ[x], Sqrt[x], "non-numeric input"]   validate before computing
```

## Common Gotchas

1. **Capitalization matters.** `sin[x]` returns unevaluated; must be `Sin[x]`.
2. **Multiplication.** `2x` works, but `xy` is a single symbol named "xy". Write `x*y` or `x y` (with a space).
3. **Equality.** `=` assigns, `==` tests equality, `===` tests structural identity.
4. **Derivative syntax.** `f'[x]` works inside Wolfram code but the apostrophe requires careful shell quoting. Use double-quoted arguments.
5. **Semicolons.** A trailing `;` suppresses the output of that line, which keeps Module output clean.
6. **Pi, E, I, Infinity.** Always capitalized.
7. **Delayed vs. immediate.** `:=` re-evaluates each time the left side is matched; `=` evaluates once at definition time.
