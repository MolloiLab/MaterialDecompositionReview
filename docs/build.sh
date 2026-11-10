#!/usr/bin/env bash
# Build the static site into docs/dist: verify the committed notebook export, then run Therapy.
# This is what .github/workflows/docs.yml runs, and what Snapshot runs (../snapshot.toml).
#
#   docs/build.sh
#
# The notebook is never rendered here: it may run simulations a CI runner cannot. Render it with
# docs/render_notebook.sh and commit docs/notebook-static/.
#
# To look at the build locally, serve it under its base path:
#   mkdir -p /tmp/site && ln -sfn "$PWD/docs/dist" /tmp/site/MaterialDecompositionReview
#   python3 -m http.server -d /tmp/site    # http://localhost:8000/MaterialDecompositionReview/
set -euo pipefail
cd "$(dirname "$0")"
export JULIAUP_CHANNEL="${JULIAUP_CHANNEL:-1.12}"

echo "▶ verify the committed notebook export"
python3 verify_notebook_export.py

echo "▶ instantiate the site environment"
julia --startup-file=no --project=. -e 'using Pkg; Pkg.instantiate()'

echo "▶ build the site"
julia --startup-file=no --project=. app.jl build

echo "✓ docs/dist ready ($(find dist -type f | wc -l | tr -d ' ') files)"
