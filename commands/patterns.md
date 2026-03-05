---
name: patterns
description: Browse common Wolfram computation patterns
argument-hint: [keyword-or-number]
allowed-tools: Read
---

The plugin ships with 15 numbered, copy-paste-ready computation patterns in
`${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/references/common-patterns.md`.

Present them based on the user's argument:

**If no argument was provided** (`$ARGUMENTS` is empty):
Show this index:
1. Quick Calculation
2. Symbolic Result with LaTeX
3. Solve and Format
4. 2D Plot to File
5. 3D Surface
6. Data Analysis Pipeline
7. Differential Equations
8. Matrix Operations
9. Number Theory
10. Export Data as CSV or JSON
11. Unit Conversions
12. Optimization
13. Fourier / Laplace Transforms
14. Probability and Distributions
15. Image Processing

Tell the user they can run `/wolfram-hart:patterns <number>` or
`/wolfram-hart:patterns <keyword>` to see a specific pattern.

**If a number or keyword was provided** (e.g. `7`, `plot`, `ODE`, `matrix`):
Use the Read tool to read
`${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/references/common-patterns.md`,
then extract and display only the matching pattern(s) in full, including the bash
invocation and expected output. Match by section number or case-insensitive keyword
in the title/content. If no match, suggest the closest patterns from the index above.

If the Read tool fails (file not found), tell the user the patterns reference could
not be loaded and suggest running `/wolfram-hart:check` to verify the installation.
