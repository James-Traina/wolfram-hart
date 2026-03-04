#!/usr/bin/env python3
"""
score_plugin.py — 10-dimension plugin scorer for wolfram-hart

Scores the plugin 1-5 across 10 quality dimensions (50 max).
Every test is deterministic, zero-touch, no LLM-as-judge.
Zero dependencies beyond Python 3.11+ stdlib.

Usage:
    python3 score_plugin.py [repo_root]

Output:
    Terminal scorecard + tests/eval-framework/report.json
"""

import json
import os
import re
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Resolve repo root
# ---------------------------------------------------------------------------
REPO_ROOT = Path(os.environ.get("REPO_ROOT", sys.argv[1] if len(sys.argv) > 1 else ".")).resolve()

if not REPO_ROOT.is_dir():
    print(f"ERROR: '{REPO_ROOT}' is not a directory. "
          f"Pass the repo root as an argument or set REPO_ROOT.", file=sys.stderr)
    sys.exit(2)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def read_path(p):
    """Read an absolute Path, return contents or empty string on error."""
    try:
        return p.read_text(encoding="utf-8", errors="replace")
    except (OSError, IOError):
        return ""


def read_text(rel_path):
    """Read a file relative to REPO_ROOT, return contents or empty string."""
    return read_path(REPO_ROOT / rel_path)


def find_files(pattern, directory=None):
    """Glob for files relative to REPO_ROOT (or a subdirectory)."""
    base = REPO_ROOT / directory if directory else REPO_ROOT
    return list(base.rglob(pattern)) if base.is_dir() else []


def score_from_deductions(deductions):
    """Score = max(1, 5 - len(deductions)). Takes a list of finding strings."""
    return max(1, 5 - len(deductions))


# ---------------------------------------------------------------------------
# Cached file lists and contents (computed once, used across dimensions)
# ---------------------------------------------------------------------------

_cache = {}

def _init_cache():
    if _cache:
        return
    # Build in a local dict so a mid-init failure doesn't leave partial state
    local = {}
    local["sh"] = [p for p in REPO_ROOT.rglob("*.sh") if ".git" not in p.parts]
    local["md"] = [p for p in REPO_ROOT.rglob("*.md") if ".git" not in p.parts]
    local["main"] = [p for p in local["sh"] if not p.name.startswith("_")]
    local["eval_sh"] = read_text("skills/wolfram-hart/scripts/wolfram-eval.sh")
    local["readme"] = read_text("README.md")
    local["skill"] = read_text("skills/wolfram-hart/SKILL.md")
    local["batch_files"] = find_files("batch-*.sh", "tests")
    local["batch_text"] = "".join(read_path(p) for p in local["batch_files"])
    _cache.update(local)


def sh_files():
    _init_cache()
    return _cache["sh"]

def md_files():
    _init_cache()
    return _cache["md"]

def main_scripts():
    _init_cache()
    return _cache["main"]

def eval_sh():
    _init_cache()
    return _cache["eval_sh"]

def readme():
    _init_cache()
    return _cache["readme"]

def skill_md():
    _init_cache()
    return _cache["skill"]

def batch_files():
    _init_cache()
    return _cache["batch_files"]

def batch_text():
    _init_cache()
    return _cache["batch_text"]


# ---------------------------------------------------------------------------
# Dimension 1: Autonomous
# ---------------------------------------------------------------------------

def score_autonomous():
    findings = []

    # A: No interactive prompts in any .sh file
    interactive_patterns = [r'\bread\s+-p\b', r'\bselect\s+\S+\s+in\b', r'\bdialog\b']
    for p in sh_files():
        text = read_path(p)
        for pat in interactive_patterns:
            for m in re.finditer(pat, text):
                findings.append(f"Interactive prompt in {p.name}: '{m.group()}'")

    # B: SKILL.md contains autonomy language
    autonomy_phrases = ["compute immediately", "without asking", "no confirmation"]
    if not any(phrase in skill_md().lower() for phrase in autonomy_phrases):
        findings.append("SKILL.md missing autonomy language (compute immediately / without asking / no confirmation)")

    # C: $1 has ${1:?} guard, $2 has ${2:-} default in main scripts
    es = eval_sh()
    if es:
        if not re.search(r'\$\{1:\?', es):
            findings.append("wolfram-eval.sh: $1 lacks ${1:?} guard")
        if not re.search(r'\$\{2:-', es):
            findings.append("wolfram-eval.sh: $2 lacks ${2:-} default")

    # D: No command .md says "ask user before" / "confirm before running"
    for p in find_files("*.md", "commands"):
        text = read_path(p).lower()
        if "ask user before" in text or "confirm before running" in text:
            findings.append(f"{p.name} contains 'ask user before' or 'confirm before running'")

    return score_from_deductions(findings), findings


# ---------------------------------------------------------------------------
# Dimension 2: Minimal
# ---------------------------------------------------------------------------

def score_minimal():
    findings = []

    # File category limits
    limits = {
        "scripts": 225,    # .sh files in scripts/
        "commands": 80,    # .md files in commands/
        "references": 300, # .md files in references/
        "skill": 250,      # SKILL.md
        "agent": 150,      # agent .md files
    }

    def check_limit(path, category, limit):
        lines = len(read_path(path).splitlines())
        if lines > limit:
            findings.append(f"{path.name}: {lines} lines (limit {limit} for {category})")

    for p in find_files("*.sh", "skills/wolfram-hart/scripts"):
        check_limit(p, "scripts", limits["scripts"])

    for p in find_files("*.md", "commands"):
        check_limit(p, "commands", limits["commands"])

    for p in find_files("*.md", "skills/wolfram-hart/references"):
        check_limit(p, "references", limits["references"])

    # Use read_text directly instead of exists() + read to avoid TOCTOU
    if skill_md():
        skill_path = REPO_ROOT / "skills/wolfram-hart/SKILL.md"
        check_limit(skill_path, "skill", limits["skill"])

    for p in find_files("*.md", "agents"):
        check_limit(p, "agent", limits["agent"])

    # B: No TODO/FIXME/HACK/XXX in .sh files
    todo_pattern = re.compile(r'#\s*(TODO|FIXME|HACK|XXX)\b', re.IGNORECASE)
    for p in sh_files():
        text = read_path(p)
        for m in todo_pattern.finditer(text):
            findings.append(f"{p.name}: contains {m.group().strip()}")

    # C: All .sh and .md files are non-empty
    for p in sh_files() + md_files():
        if not read_path(p):
            findings.append(f"{p.name}: empty file")

    return score_from_deductions(findings), findings


# ---------------------------------------------------------------------------
# Dimension 3: Modular
# ---------------------------------------------------------------------------

def score_modular():
    findings = []

    # A: Non-helper scripts only source _-prefixed files
    source_pattern = re.compile(r'\bsource\s+["\']?([^\s"\']+)')
    for p in main_scripts():
        text = read_path(p)
        for m in source_pattern.finditer(text):
            sourced = m.group(1)
            basename = sourced.rsplit("/", 1)[-1] if "/" in sourced else Path(sourced).name
            if not basename.startswith("_") and basename.endswith(".sh"):
                # Allow sourcing helpers.sh from test runner
                if basename == "helpers.sh" and "tests" in str(p):
                    continue
                findings.append(f"{p.name}: sources non-helper '{basename}'")

    # B: Agent tools contain no write tools
    write_tools = {"Write", "Edit", "Bash", "NotebookEdit"}
    for p in find_files("*.md", "agents"):
        text = read_path(p)
        tools_match = re.search(r'tools:\s*\[([^\]]*)\]', text)
        if tools_match:
            tools_str = tools_match.group(1)
            for wt in write_tools:
                if re.search(r'\b' + wt + r'\b', tools_str):
                    findings.append(f"{p.name}: agent has write tool '{wt}'")

    # C: No command .md references another command's .md path
    cmd_files = find_files("*.md", "commands")
    cmd_names = {p.name for p in cmd_files}
    for p in cmd_files:
        text = read_path(p)
        for other_name in cmd_names:
            if other_name != p.name and other_name in text:
                findings.append(f"{p.name}: references command '{other_name}'")

    # D: plugin.json has no hooks/scripts/preInstall/postInstall keys
    pj = read_text(".claude-plugin/plugin.json")
    if pj:
        try:
            pj_data = json.loads(pj)
            for key in ["hooks", "scripts", "preInstall", "postInstall"]:
                if key in pj_data:
                    findings.append(f"plugin.json: has '{key}' key")
        except json.JSONDecodeError:
            findings.append("plugin.json: invalid JSON")

    # E: <=4 executable (non-_-prefixed) scripts in scripts/
    exec_scripts = [p for p in find_files("*.sh", "skills/wolfram-hart/scripts")
                    if not p.name.startswith("_")]
    if len(exec_scripts) > 4:
        findings.append(f"scripts/: {len(exec_scripts)} executable scripts (limit 4)")

    return score_from_deductions(findings), findings


# ---------------------------------------------------------------------------
# Dimension 4: Robust
# ---------------------------------------------------------------------------

def score_robust():
    findings = []

    # A: Directly-executed scripts have set -euo pipefail (or -uo pipefail for
    #    test runner).  Sourced files (batch-*.sh, helpers.sh) inherit the
    #    parent's shell options and are excluded.
    executed_scripts = [
        p for p in main_scripts()
        if not p.name.startswith("batch-") and p.name != "helpers.sh"
    ]
    for p in executed_scripts:
        text = read_path(p)
        if not re.search(r'set\s+-[eu]*o\s+pipefail', text):
            findings.append(f"{p.name}: missing 'set -euo pipefail' (or variant)")

    # B: Directly-executed scripts using mktemp have trap cleanup (sourced
    #    files manage tmp lifetime within functions, so they are excluded)
    for p in executed_scripts:
        text = read_path(p)
        if "mktemp" in text and not re.search(r"trap\s+.*EXIT", text):
            findings.append(f"{p.name}: uses mktemp without trap ... EXIT")

    # C: All 4 exit codes (0,1,2,3) tested across batch files
    bt = batch_text()
    for code in ["0", "1", "2", "3"]:
        # Require LAST_EXIT in the match to avoid false positives from
        # computation-result assertions (e.g., assert_eq "4" which is math output)
        pattern = re.compile(r'LAST_EXIT.*["\']' + code + r'["\']')
        if not pattern.search(bt):
            findings.append(f"Tests: no assertion found for exit code {code}")

    # D: batch-10.sh exists with >=8 test_ functions
    batch10 = read_text("tests/batch-10.sh")
    if not batch10:
        findings.append("tests/batch-10.sh does not exist")
    else:
        test_funcs = re.findall(r'^test_\w+\s*\(\)', batch10, re.MULTILINE)
        if len(test_funcs) < 8:
            findings.append(f"batch-10.sh: {len(test_funcs)} test functions (need >=8)")

    # E: wolfram-eval.sh uses printf '%s\n' for result output
    if eval_sh() and "printf '%s\\n'" not in eval_sh():
        findings.append("wolfram-eval.sh: does not use printf '%s\\n' for result output")

    return score_from_deductions(findings), findings


# ---------------------------------------------------------------------------
# Dimension 5: Genuine
# ---------------------------------------------------------------------------

def score_genuine():
    findings = []

    rm = readme()
    es = eval_sh()

    # A: Exit codes in README match script
    readme_codes = set(re.findall(r'\|\s*(\d)\s*\|', rm))
    script_codes = set(re.findall(r'\bexit\s+(\d)\b', es))
    missing_in_readme = script_codes - readme_codes
    missing_in_script = readme_codes - script_codes
    if missing_in_readme:
        findings.append(f"Exit codes in script but not README: {missing_in_readme}")
    if missing_in_script:
        findings.append(f"Exit codes in README but not script: {missing_in_script}")

    # B: Sentinels present in both script and README
    sentinels = ["NOT_INSTALLED", "NOT_CONFIGURED", "TIMEOUT", "---WARNINGS---"]
    for s in sentinels:
        in_script = s in es
        in_readme = s in rm
        if not in_script and not in_readme:
            findings.append(f"Sentinel '{s}' missing from both eval script and README")
        elif not in_script:
            findings.append(f"Sentinel '{s}' in README but missing from eval script")
        elif not in_readme:
            findings.append(f"Sentinel '{s}' in eval script but missing from README")

    # C: Key filenames in README exist in repo
    file_refs = re.findall(r'^\s+(\S+\.(?:sh|md|json))\s', rm, re.MULTILINE)
    for fname in file_refs:
        matches = list(REPO_ROOT.rglob(fname))
        if not matches:
            findings.append(f"README references '{fname}' but file not found in repo")

    # D: WOLFRAM_MODE appears in both README and at least one script
    if "WOLFRAM_MODE" not in rm:
        findings.append("WOLFRAM_MODE not referenced in README")
    if not any("WOLFRAM_MODE" in read_path(p) for p in sh_files()):
        findings.append("WOLFRAM_MODE not used in any script")

    return score_from_deductions(findings), findings


# ---------------------------------------------------------------------------
# Dimension 6: Precise
# ---------------------------------------------------------------------------

def score_precise():
    findings = []

    es = eval_sh()

    # A: eval script has printf '%s pattern for output
    if not re.search(r"printf\s+'%s", es):
        findings.append("wolfram-eval.sh: missing printf '%s...' pattern for output")

    # B: No debug output in main scripts
    debug_patterns = [r'echo\s+"DEBUG', r'echo\s+"INFO', r'echo\s+"LOG', r'\bset\s+-x\b']
    for p in main_scripts():
        if "tests" in str(p):
            continue
        text = read_path(p)
        for pat in debug_patterns:
            if re.search(pat, text):
                findings.append(f"{p.name}: contains debug output pattern '{pat}'")

    # C: ---WARNINGS--- literal in eval script
    if "---WARNINGS---" not in es:
        findings.append("wolfram-eval.sh: missing ---WARNINGS--- separator")

    # D: Sentinel echo/printf lines use UPPER_CASE: format
    sentinel_lines = re.findall(r"(?:echo|printf\s+'%s\\n')\s+[\"']([A-Z_]+:.*?)[\"']", es)
    if not sentinel_lines:
        heredoc_sentinels = re.findall(r'^([A-Z_]+):.*$', es, re.MULTILINE)
        if not heredoc_sentinels:
            findings.append("wolfram-eval.sh: no UPPER_CASE: sentinel format found")

    return score_from_deductions(findings), findings


# ---------------------------------------------------------------------------
# Dimension 7: Rigorous
# ---------------------------------------------------------------------------

def score_rigorous():
    findings = []

    # A: Count test_NNN functions across batches — threshold scoring
    bf = batch_files()
    total_tests = 0
    for p in bf:
        total_tests += len(re.findall(r'^test_\w+\s*\(\)', read_path(p), re.MULTILINE))

    thresholds = [(90, 0), (70, 1), (50, 2), (20, 3)]
    deductions = 4
    for threshold, d in thresholds:
        if total_tests >= threshold:
            deductions = d
            break
    for i in range(deductions):
        findings.append(f"Test count: {total_tests} (need >=90, deduction {i+1}/{deductions})")

    # B: helpers.sh contains run_eval referencing wolfram-eval.sh
    helpers = read_text("tests/helpers.sh")
    if "run_eval" not in helpers:
        findings.append("helpers.sh: missing run_eval function")
    if "wolfram-eval.sh" not in helpers:
        findings.append("helpers.sh: run_eval does not reference wolfram-eval.sh")

    # C: run-tests.sh contains pass/fail summary output
    runner = read_text("tests/run-tests.sh")
    has_pass = bool(re.search(r'pass', runner, re.IGNORECASE))
    has_fail = bool(re.search(r'fail', runner, re.IGNORECASE))
    if not has_pass or not has_fail:
        findings.append("run-tests.sh: missing pass/fail summary output")

    # D: >=8 batch-*.sh files
    if len(bf) < 8:
        findings.append(f"Only {len(bf)} batch files (need >=8)")

    # E: Tests span >=4 domains
    domains_found = set()
    domain_keywords = {
        "arithmetic": [r'\b(?:2\+2|add|subtract|multiply|divide)\b', r'test_\d+_(?:basic|arith|add|mul)'],
        "algebra": [r'\bSolve\b', r'\bExpand\b', r'\bFactor\b', r'algebra'],
        "calculus": [r'\bIntegrate\b', r'\bD\[', r'\bLimit\b', r'\bSeries\b', r'calculus'],
        "linalg": [r'\bEigenvalue', r'\bDet\b', r'\bInverse\b', r'\bMatrix', r'linalg|linear.algebra'],
        "plotting": [r'\bPlot\b', r'\bExport\b.*\.png', r'plot'],
        "edge_cases": [r'edge.case|error.handl|unevaluated|misspell'],
    }
    bt = batch_text()
    for domain, patterns in domain_keywords.items():
        for pat in patterns:
            if re.search(pat, bt, re.IGNORECASE):
                domains_found.add(domain)
                break

    if len(domains_found) < 4:
        findings.append(f"Tests span {len(domains_found)} domains (need >=4): {domains_found}")

    return score_from_deductions(findings), findings


# ---------------------------------------------------------------------------
# Dimension 8: Actionable
# ---------------------------------------------------------------------------

def score_actionable():
    findings = []

    es = eval_sh()
    check_sh = read_text("skills/wolfram-hart/scripts/wolfram-check.sh")
    rm = readme()
    eval_md = read_text("commands/eval.md")

    # A: NOT_INSTALLED block contains install/brew/download
    ni_match = re.search(r'NOT_INSTALLED.*?(?=\n(?:exit|fi|\Z))', es, re.DOTALL)
    if ni_match:
        ni_block = ni_match.group().lower()
        if not any(word in ni_block for word in ["install", "brew", "download"]):
            findings.append("NOT_INSTALLED block: missing install/brew/download remediation")
    else:
        findings.append("wolfram-eval.sh: no NOT_INSTALLED block found")

    # B: NOT_CONFIGURED block contains check/activate/authenticate
    nc_match = re.search(r'NOT_CONFIGURED.*?(?=\n(?:exit|fi|\Z))', es, re.DOTALL)
    if nc_match:
        nc_block = nc_match.group().lower()
        if not any(word in nc_block for word in ["check", "activate", "authenticate"]):
            findings.append("NOT_CONFIGURED block: missing check/activate/authenticate remediation")
    else:
        findings.append("wolfram-eval.sh: no NOT_CONFIGURED block found")

    # C: check.sh has >=2 lines matching _hint:
    hint_count = len(re.findall(r'_hint[:\s]', check_sh))
    if hint_count < 2:
        findings.append(f"wolfram-check.sh: {hint_count} _hint fields (need >=2)")

    # D: README has ## Troubleshoot section with >=3 bold entries
    ts_match = re.search(r'##\s*Troubleshoot.*?(?=\n##\s|\Z)', rm, re.DOTALL | re.IGNORECASE)
    if ts_match:
        ts_section = ts_match.group()
        bold_entries = re.findall(r'\*\*.*?\*\*', ts_section)
        if len(bold_entries) < 3:
            findings.append(f"README Troubleshooting: {len(bold_entries)} bold entries (need >=3)")
    else:
        findings.append("README: missing ## Troubleshooting section")

    # E: eval.md references "check" on failure
    if eval_md:
        if not re.search(r'check', eval_md, re.IGNORECASE):
            findings.append("eval.md: does not reference 'check' on failure paths")

    return score_from_deductions(findings), findings


# ---------------------------------------------------------------------------
# Dimension 9: Specialized
# ---------------------------------------------------------------------------

def score_specialized():
    findings = []

    # A: >=2 reference files in references/
    ref_files = find_files("*.md", "skills/wolfram-hart/references")
    if len(ref_files) < 2:
        findings.append(f"references/: {len(ref_files)} files (need >=2)")

    # B: Each reference file contains >=3 Wolfram function names
    wolfram_functions = [
        "Solve", "Integrate", "Plot", "D[", "Limit", "Series", "Expand", "Factor",
        "Simplify", "NSolve", "FindRoot", "DSolve", "NDSolve", "Eigenvalues",
        "Det", "Inverse", "LinearSolve", "Export", "Module", "Table", "Sum",
        "Product", "FourierTransform", "LaplaceTransform", "NMinimize", "Plot3D",
        "ListPlot", "ContourPlot", "ParametricPlot", "Mean", "Median",
        "StandardDeviation", "FactorInteger", "PrimeQ", "UnitConvert",
    ]
    for p in ref_files:
        text = read_path(p)
        count = sum(1 for fn in wolfram_functions if fn in text)
        if count < 3:
            findings.append(f"{p.name}: only {count} Wolfram functions (need >=3)")

    # C: Agent reviewer has zero generic items + >=3 Wolfram items
    for p in find_files("*.md", "agents"):
        text = read_path(p)
        generic = ["DRY", "SOLID", "design pattern"]
        for g in generic:
            if re.search(r'\b' + re.escape(g) + r'\b', text, re.IGNORECASE):
                findings.append(f"{p.name}: contains generic item '{g}'")

        wolfram_items = ["capitaliz", "bracket", "semicolon", "Export", "Module",
                         "square bracket", "Wolfram", "wolframscript"]
        wcount = sum(1 for wi in wolfram_items if wi.lower() in text.lower())
        if wcount < 3:
            findings.append(f"{p.name}: only {wcount} Wolfram-specific items (need >=3)")

    # D: >=5 gotcha/warning markers across reference files
    gotcha_patterns = [r'\b(?:gotcha|warning|caution|note|important|pitfall|trap|caveat)\b',
                       r'(?:wrong|right)\s*:', r'\bdo\s+not\b']
    gotcha_count = 0
    for p in ref_files:
        text = read_path(p)
        for pat in gotcha_patterns:
            gotcha_count += len(re.findall(pat, text, re.IGNORECASE))
    if gotcha_count < 5:
        findings.append(f"Reference files: {gotcha_count} gotcha/warning markers (need >=5)")

    # E: SKILL.md trigger area contains >=8 domain terms
    domain_terms = ["integrat", "solve", "plot", "eigenvalue", "differentiat",
                    "factor", "simplif", "statistic", "fourier", "laplace",
                    "optimiz", "minimiz", "maximiz", "linear algebra", "calculus",
                    "matrix", "probability", "differential equation"]
    trigger_area = skill_md()[:1500]
    term_count = sum(1 for t in domain_terms if t.lower() in trigger_area.lower())
    if term_count < 8:
        findings.append(f"SKILL.md trigger area: {term_count} domain terms (need >=8)")

    return score_from_deductions(findings), findings


# ---------------------------------------------------------------------------
# Dimension 10: Literate
# ---------------------------------------------------------------------------

def score_literate():
    findings = []

    rm = readme()

    # A: README >=150 lines
    readme_lines = len(rm.splitlines())
    if readme_lines < 150:
        findings.append(f"README: {readme_lines} lines (need >=150)")

    # B: Required section headings
    required_sections = ["## Prerequisites", "## Usage", "## How it works", "## Troubleshoot"]
    for section in required_sections:
        pattern = re.compile(re.escape(section), re.IGNORECASE)
        if not pattern.search(rm):
            findings.append(f"README: missing '{section}' section")

    # C: >=3 explanatory comments across scripts (stem-match: "avoids" counts
    #    for "avoid", "prevents" for "prevent", etc.)
    explanatory_patterns = [r'#.*\bbecause\b', r'#.*\binstead of\b', r'#.*\bavoid',
                            r'#.*\bprevent', r'#.*\botherwise\b', r'#.*\bdeliberate',
                            r'#.*\bintentional']
    comment_count = 0
    for p in sh_files():
        if "tests" in str(p):
            continue
        text = read_path(p)
        for pat in explanatory_patterns:
            comment_count += len(re.findall(pat, text, re.IGNORECASE))
    if comment_count < 3:
        findings.append(f"Scripts: {comment_count} explanatory comments (need >=3)")

    # D: LICENSE or LICENSE.md exists
    has_license = (REPO_ROOT / "LICENSE").exists() or (REPO_ROOT / "LICENSE.md").exists()
    if not has_license:
        findings.append("Missing LICENSE file")

    # E: README has architecture/design section
    arch_patterns = [r'##.*(?:architect|design|how it works|rationale)', r'##.*structure']
    has_arch = any(re.search(pat, rm, re.IGNORECASE) for pat in arch_patterns)
    if not has_arch:
        findings.append("README: missing architecture/design section")

    return score_from_deductions(findings), findings


# ---------------------------------------------------------------------------
# Orchestrator
# ---------------------------------------------------------------------------

DIMENSIONS = [
    ("Autonomous", score_autonomous),
    ("Minimal", score_minimal),
    ("Modular", score_modular),
    ("Robust", score_robust),
    ("Genuine", score_genuine),
    ("Precise", score_precise),
    ("Rigorous", score_rigorous),
    ("Actionable", score_actionable),
    ("Specialized", score_specialized),
    ("Literate", score_literate),
]


def run_scorecard():
    results = []
    total = 0
    perfect_count = 0

    print()
    print("WOLFRAM-HART PLUGIN SCORECARD")
    print("\u2550" * 54)

    for i, (name, scorer) in enumerate(DIMENSIONS, 1):
        score, findings = scorer()
        total += score
        is_perfect = score == 5
        if is_perfect:
            perfect_count += 1

        bar = "\u2588" * score + "\u2591" * (5 - score)
        mark = "\u2713" if is_perfect else "\u2717"
        print(f"  {i:2d}. {name:<14s} {bar} {score}/5  {mark}")

        if findings:
            for f in findings:
                print(f"      \u2192 {f}")

        results.append({
            "dimension": name,
            "score": score,
            "max": 5,
            "perfect": is_perfect,
            "findings": findings,
        })

    max_score = len(DIMENSIONS) * 5
    print("\u2500" * 54)
    print(f" TOTAL: {total}/{max_score}  ({perfect_count} perfect)")
    print()

    # Write JSON report
    report = {
        "plugin": "wolfram-hart",
        "total_score": total,
        "max_score": max_score,
        "perfect_dimensions": perfect_count,
        "dimensions": results,
    }

    report_path = REPO_ROOT / "tests" / "eval-framework" / "report.json"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    print(f"Report written to {report_path.relative_to(REPO_ROOT)}")

    return total, max_score


if __name__ == "__main__":
    total, max_score = run_scorecard()
    sys.exit(0 if total == max_score else 1)
