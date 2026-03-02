---
description: Verify Wolfram Engine installation and license
allowed-tools: Bash(bash:*)
---

Run the Wolfram Engine installation check:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/wolfram-hart/scripts/wolfram-check.sh
```

Interpret the key-value output and present a clear status summary:

- **status**: Whether wolframscript was found.
- **path**: Where the binary lives.
- **version**: The installed version string.
- **licensed**: Whether the license is active (`YES` is good; `POSSIBLY_NO` means
  the user needs to run `wolframscript` interactively to complete activation).
- **test**: The sanity check result (`2+2 = 4` confirms everything works).
- **engine**: Version number, platform, and core count.

If the status is `NOT_FOUND`, present the installation instructions from the output
and offer platform-specific guidance (Homebrew for macOS, .deb/.rpm for Linux).

If licensed is `POSSIBLY_NO`, explain that the user should run `wolframscript` in
their terminal once to complete the license activation flow.
