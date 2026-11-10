# What the page says about itself, in one place. Loaded first (components load in name order).

# The site's base path: empty on the local dev server, "/MaterialDecompositionReview" on GitHub
# Pages. docs/app.jl sets it.
const BASE = get(ENV, "MDREVIEW_BASE", "")

const SITE_TITLE = "Material Decomposition in CT"
const REPO_URL = "https://github.com/MolloiLab/MaterialDecompositionReview"
const NOTEBOOK_URL = "$(REPO_URL)/blob/main/notebooks/material_decomposition.jl"
# The paper's link. Until the PDF has an address this opens the manuscript's folder; replace it
# with the PDF or the DOI.
const PAPER_URL = "$(REPO_URL)/tree/main/paper"
