#!/usr/bin/env bash
# Re-render the notebook's export (docs/notebook-static/) and verify it. Commit the result.
#
#   docs/render_notebook.sh            # render if the export is stale
#   docs/render_notebook.sh --force    # render whether stale or not
#
# Runs on Julia 1.12 (through juliaup, or whatever `julia` is when JULIAUP_CHANNEL has no effect):
# under 1.13 the island compiler compiles nothing for some sliders. The notebook runs in the
# repository's root environment, locked for 1.12 in Manifest-v1.12.toml; this script creates that
# file the first time and brings it up to date when Project.toml has changed. A render runs the
# whole notebook, so it rewrites what the notebook writes (results/, paper/figures/).
#
# The export stops after MDREVIEW_RENDER_TIMEOUT seconds (default 3600; raise it when the notebook
# itself runs longer). A notebook that runs in minutes and still reaches the limit has a cell
# downstream of a slider that calls code WebAssembly cannot run: the island compiler then works
# on it without returning.
set -euo pipefail
cd "$(dirname "$0")"
export JULIAUP_CHANNEL="${JULIAUP_CHANNEL:-1.12}"
limit="${MDREVIEW_RENDER_TIMEOUT:-3600}"

[ -f ../notebooks/material_decomposition.jl ] || { echo "no notebooks/material_decomposition.jl" >&2; exit 1; }
[ -f ../Manifest-v1.12.toml ] || : > ../Manifest-v1.12.toml
julia --startup-file=no --project=.. -e 'using Pkg; Pkg.resolve(); Pkg.instantiate()'
julia --startup-file=no --project=build_env -e 'using Pkg; Pkg.instantiate()'

export_cmd=(julia --startup-file=no --project=build_env export_notebook.jl "$@")
if command -v timeout > /dev/null 2>&1; then
    status=0
    timeout -k 30 "$limit" "${export_cmd[@]}" || status=$?
    if [ "$status" -eq 124 ]; then
        echo "the export did not finish in $limit s (MDREVIEW_RENDER_TIMEOUT)." >&2
        echo "If the notebook itself is fast, a cell downstream of a slider calls code that cannot compile to WebAssembly." >&2
    fi
    [ "$status" -eq 0 ] || exit "$status"
else
    "${export_cmd[@]}"
fi
python3 verify_notebook_export.py
