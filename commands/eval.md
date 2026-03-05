---
name: eval
description: Execute Wolfram Language code directly
argument-hint: <wolfram-code> [timeout]
allowed-tools: Bash(bash:*), Read
---

Execute the following Wolfram Language code through the plugin's eval script:

```
$ARGUMENTS
```

**Execution steps:**

0. If `$ARGUMENTS` is empty or contains only whitespace, do not invoke the script.
   Tell the user: "No Wolfram code provided. Usage:
   `/wolfram-hart:eval <wolfram-code> [timeout]`" and show a brief example like
   `/wolfram-hart:eval Solve[x^2 == 4, x]`.

1. Parse the input. If the last whitespace-separated token is a bare integer >= 10
   (e.g. `60`, `120`), treat it as a timeout override in seconds; everything before
   it is the Wolfram code. Otherwise, the entire input is the code and the default
   30-second timeout applies. This threshold avoids misinterpreting small numbers
   that are part of the Wolfram expression itself.

2. Run the code through the wrapper script:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/scripts/wolfram-eval.sh '<code>' [timeout]
```

Use single quotes around the code. If the code contains derivative apostrophes
(`y'[x]`), switch to double quotes and escape inner double quotes with `\"` and
dollar signs with `\$` (e.g. `\$VersionNumber`).

3. Interpret the result:
   - If exit code 0 and stdout is empty: the code ran but produced no output. Tell
     the user this usually means the final expression evaluates to `Null` (e.g.
     because it ends with a semicolon). Suggest removing the trailing semicolon.
   - If stdout is a file path (from `Export`), use the Read tool to display the image.
   - If stdout contains `---WARNINGS---`, separate the result from warnings and
     present both.
   - If exit code 1: wolframscript is not installed. Run
     `bash ${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/scripts/wolfram-check.sh`
     and relay install instructions.
   - If exit code 2: execution error. Show the error and suggest corrections.
   - If exit code 3: timeout. Suggest increasing the timeout or simplifying the code.
   - For any other non-zero exit code: report the exit code and any stderr output.
     Suggest running `/wolfram-hart:check` to verify the installation.

4. Present the result directly. Do not add extra commentary unless there is an error
   or warning to explain.
