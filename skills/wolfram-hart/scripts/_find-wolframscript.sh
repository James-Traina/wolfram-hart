#!/usr/bin/env bash
#
# _find-wolframscript.sh — shared wolframscript discovery
#
# Sourced by wolfram-eval.sh and wolfram-check.sh (not executed directly).
# Sets WOLFRAMSCRIPT to the first executable candidate found, or leaves it
# empty if wolframscript is not installed.
#
# Search order: PATH first, then well-known install locations on macOS
# (Homebrew ARM/Intel, system, and app-bundle paths) and Linux.

WOLFRAMSCRIPT=""
for candidate in \
    "$(command -v wolframscript 2>/dev/null || true)" \
    "/opt/homebrew/bin/wolframscript" \
    "/usr/local/bin/wolframscript" \
    "/usr/bin/wolframscript" \
    "/Applications/Wolfram Engine.app/Contents/MacOS/wolframscript" \
    "/Applications/Mathematica.app/Contents/MacOS/wolframscript" \
    "/snap/bin/wolframscript"; do
    if [[ -n "$candidate" && -x "$candidate" ]]; then
        WOLFRAMSCRIPT="$candidate"
        break
    fi
done
