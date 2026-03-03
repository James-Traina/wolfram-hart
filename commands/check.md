---
description: Check Wolfram Engine setup (local and cloud) and show configuration status
allowed-tools: Bash(bash:*)
---

Run the Wolfram setup check:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/scripts/wolfram-check.sh
```

If the script itself fails to run (file not found, permission denied), report the
error and suggest verifying the plugin installation.

The output is divided into four sections: top-level info, `--- local ---`,
`--- cloud ---`, and `--- setup ---`. Interpret them as follows:

**Top-level fields**

- **status**: `FOUND` (binary located) or `NOT_FOUND`. If `NOT_FOUND`, present
  the setup options from the output and stop.
- **path**: Where the `wolframscript` binary lives.
- **mode_set**: The active `WOLFRAM_MODE` value (`auto`, `local`, or `cloud`).
- **version**: Installed version. If `UNKNOWN`, the version check failed and
  the installation may be incomplete.

**Local section (`--- local ---`)**

- **local_licensed**: `YES` means the local Engine is installed and licensed.
  `POSSIBLY_NO` means the sanity check failed. `TIMEOUT` means the check
  exceeded 15 s (the kernel may be slow to start — retry or increase timeout).
- **local_test**: Appears when `local_licensed` is `YES`; confirms `2+2 = 4`.
- **local_test_output**: Always present when `local_licensed` is `POSSIBLY_NO`;
  shows what wolframscript printed to stdout during the check.
- **local_test_stderr**: Also appears when `local_licensed` is `POSSIBLY_NO`,
  but only when wolframscript wrote to stderr. May be absent if stderr was empty.
- **local_hint**: Fixed string emitted in the failure case:
  `run 'wolframscript' interactively to complete activation`.
- **engine**: Engine version, platform, and core count. Only appears when
  `local_licensed` is `YES`. If `UNKNOWN`, there may be a license issue.

**Cloud section (`--- cloud ---`)**

- **cloud_available**: `YES` (cloud evaluation works), `NO` (not configured or
  auth failed), or `TIMEOUT` (no response within 30 s — likely a network issue).
- **cloud_test**: Appears when `cloud_available` is `YES`; confirms `2+2 = 4`.
- **cloud_test_output**: Appears when `cloud_available` is `NO`; shows what
  wolframscript printed to stdout during the check.
- **cloud_test_stderr**: Also appears when `cloud_available` is `NO`, but only
  when wolframscript wrote to stderr. May be absent if stderr was empty.
- **cloud_hint**: Fixed string per outcome. When `cloud_available` is `NO`:
  `run 'wolframscript -authenticate' to set up cloud access`. When
  `cloud_available` is `TIMEOUT`:
  `cloud check timed out after 30s; check network connectivity and retry`.

**Setup section (`--- setup ---`)**

- **recommended_mode**: The suggested `WOLFRAM_MODE` value given what's
  working. Possible values:
  - `auto (both local and cloud are available)`
  - `local (Engine licensed; cloud not configured)`
  - `cloud`
  - `NONE — neither mode is working`
- **recommended_action**: A user-facing instruction (e.g.,
  `add 'export WOLFRAM_MODE=cloud' to ~/.zshrc or ~/.bashrc`). Only appears
  when cloud works but local does not. When neither mode works, the script
  instead emits `To fix local:` and `To fix cloud:` lines with step-by-step
  instructions; relay those directly.

Summarize the status clearly: which modes are working, which aren't, and what
the user should do next. Use the `recommended_action` field directly when
present — it is already a user-facing instruction.
