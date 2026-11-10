#!/usr/bin/env python3
"""Refuse a missing, stale, broken or machine-specific notebook export.

The site ships the committed export in docs/notebook-static/ and CI never renders it. This check
recomputes the fingerprint that docs/export_notebook.jl records in the fragment, and reads the
island compiler's report: every `@bind` group must be a verified WebAssembly island, or a fallback
that the export contract names.

Ported from docs/verify_notebook_exports.py of BasisSimulator.jl (MIT, MolloiLab), reduced to one
notebook. Needs only the Python standard library.
"""

from pathlib import Path
import hashlib
import json
import re
import sys

DOCS = Path(__file__).resolve().parent
ROOT = DOCS.parent
SLUG = "material_decomposition"
NOTEBOOK = ROOT / "notebooks" / f"{SLUG}.jl"
STATIC = DOCS / "notebook-static"
FRAGMENT = STATIC / f"{SLUG}.fragment.html"
ISLANDS = STATIC / f"{SLUG}.islands"
HASH_MARK = "mdreview-export-fingerprint"

BAD_HTML = {
    "a cell that raised an error": "<jlerror",
    "a serialized Pluto exception": "plain_error",
    "a fragment that overrides the site's theme": "localstorage.getitem('snap-theme')",
}
BAD_PATHS = {
    "macOS user path": re.compile(r"/(?:private/)?Users/[^/\s<]+/"),
    "Unix home path": re.compile(r"/home/[^/\s<]+/"),
    "cluster home path": re.compile(r"/data/[^/\s<\"']+/[^/\s<\"']+/"),
    "temporary path": re.compile(r"/(?:private/)?tmp/[^\s<\"']+"),
    "mounted volume path": re.compile(r"/Volumes/[^\s<\"']+"),
    "Julia depot path": re.compile(r"/\.julia/(?:packages|dev|compiled)/"),
}
TEXT_SUFFIXES = {".html", ".json", ".js", ".css", ".map", ".txt"}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def export_contract() -> str:
    """EXPORT_CONTRACT of docs/export_notebook.jl, read from its one definition."""
    source = (DOCS / "export_notebook.jl").read_text(encoding="utf-8")
    return re.search(r'^const EXPORT_CONTRACT = "([^"]*)"', source, re.M).group(1)


def export_fingerprint(contract: str) -> str:
    """export_fingerprint in docs/export_notebook.jl."""
    parts = (
        sha256(NOTEBOOK.read_bytes()),
        sha256((ROOT / "Manifest-v1.12.toml").read_bytes()),
        sha256((DOCS / "build_env" / "Manifest.toml").read_bytes()),
        contract,
    )
    return sha256("\0".join(parts).encode("utf-8"))


def check_islands(contract: str) -> list:
    """Every group is a verified island, or a fallback the contract names."""
    forced = {b for b in contract.split("forced-fallback=")[-1].split(",") if b}
    source = NOTEBOOK.read_text(encoding="utf-8")
    if not ISLANDS.is_dir():
        # A notebook without controls has no islands. One with controls must have them.
        has_controls = re.search(r"^[^#\n]*@bind\b", source, re.M) is not None
        return ["the notebook has @bind controls but the export has no islands"] if has_controls else []
    failures = []
    for name in ("report.json", "coverage.json", "islands.json", "shim.js"):
        if not (ISLANDS / name).is_file():
            failures.append(f"{ISLANDS.name}/{name}: missing")
    if failures:
        return failures
    groups = json.loads((ISLANDS / "report.json").read_text(encoding="utf-8"))
    runtime = json.loads((ISLANDS / "islands.json").read_text(encoding="utf-8"))
    cells = set(re.findall(r"^# ╔═╡ ([0-9a-f-]{36})\s*$", source, re.M))
    n_islands = 0
    for group in groups:
        bonds = group.get("bonds", [])
        ids = {str(c.get("id")) for c in group.get("cells", [])}
        if not ids <= cells:
            failures.append(f"@bind {bonds}: a cell that is not in the notebook")
        elif ids and group.get("judgement") == "island" and all(c.get("ok") is True for c in group["cells"]):
            n_islands += 1
        elif group.get("fallback_kind") == "configured" and set(bonds) <= forced:
            continue
        else:
            reasons = list(group.get("reasons", []))
            reasons += [r for c in group.get("cells", []) for r in c.get("reasons", [])]
            why = (reasons[0] if reasons else "no reason recorded").splitlines()[0][:200]
            failures.append(f"@bind {bonds} did not compile to an island: {why}")
    if len(runtime.get("groups", [])) != n_islands:
        failures.append(f"{ISLANDS.name}/islands.json does not match report.json")
    for group in runtime.get("groups", []):
        module = group.get("wasm")
        if not module or not (ISLANDS / module).is_file():
            failures.append(f"{ISLANDS.name}/{module}: missing WebAssembly module")
    return failures


def main() -> int:
    if not NOTEBOOK.is_file():
        print(f"no notebook at {NOTEBOOK.relative_to(ROOT)}", file=sys.stderr)
        return 1
    if not FRAGMENT.is_file():
        print(f"no export at {FRAGMENT.relative_to(ROOT)}: run docs/render_notebook.sh", file=sys.stderr)
        return 1
    if not (ROOT / "Manifest-v1.12.toml").is_file():
        print("no Manifest-v1.12.toml at the repository root: run docs/render_notebook.sh", file=sys.stderr)
        return 1
    contract = export_contract()
    failures = []

    text = FRAGMENT.read_text(encoding="utf-8", errors="replace")
    recorded = re.search(rf"<!-- {HASH_MARK}: ([0-9a-f]{{64}}) -->", text)
    expected = export_fingerprint(contract)
    if recorded is None or recorded.group(1) != expected:
        found = recorded.group(1)[:12] if recorded else "none"
        failures.append(
            f"stale export (inputs {expected[:12]}, export {found}): run docs/render_notebook.sh"
        )
    lowered = text.lower()
    for label, needle in BAD_HTML.items():
        if needle in lowered:
            failures.append(f"{FRAGMENT.name}: {label}")
    failures.extend(check_islands(contract))

    for artifact in sorted(STATIC.rglob("*")):
        if not artifact.is_file() or artifact.suffix.lower() not in TEXT_SUFFIXES:
            continue
        content = artifact.read_text(encoding="utf-8", errors="replace")
        for label, pattern in BAD_PATHS.items():
            match = pattern.search(content)
            if match:
                failures.append(f"{artifact.relative_to(STATIC)}: {label} ({match.group(0)!r})")

    if failures:
        print("the committed notebook export is not publishable:", file=sys.stderr)
        print("\n".join(f"  - {failure}" for failure in failures), file=sys.stderr)
        return 1
    n = len(list(ISLANDS.glob("*.wasm"))) if ISLANDS.is_dir() else 0
    print(f"verified the export of {SLUG}: fingerprint {expected[:12]}, {n} WebAssembly module(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
