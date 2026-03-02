---
description: Verify Wolfram Engine installation and license
allowed-tools: Bash(bash:*)
---

Run the Wolfram Engine installation check:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/scripts/wolfram-check.sh
```

If the script itself fails to run (file not found, permission denied), report the
error and suggest verifying the plugin installation.

Interpret the key-value output and present a clear status summary:

- **status**: Whether wolframscript was found.
- **path**: Where the binary lives.
- **version**: The installed version string. If the value is `UNKNOWN`, explain that
  the version check failed and the installation may be incomplete.
- **licensed**: Whether the license is active (`YES` is good; `POSSIBLY_NO` means
  the user needs to run `wolframscript` interactively to complete activation).
- **test**: The sanity check result (`2+2 = 4` confirms everything works). This field
  only appears when the check succeeds.
- **test_output** / **test_stderr**: If present (when licensed is `POSSIBLY_NO`),
  display these so the user can see what wolframscript returned during the sanity check.
- **hint**: Suggested user action (appears in the failure case).
- **engine**: Version number, platform, and core count. If `UNKNOWN`, the engine
  details could not be retrieved, which may indicate a license or installation issue.

If the status is `NOT_FOUND`, present the installation instructions from the output
and offer platform-specific guidance (Homebrew for macOS, .deb/.rpm for Linux).

If licensed is `POSSIBLY_NO`, explain that the user should run `wolframscript` in
their terminal once to complete the license activation flow.
