#!/usr/bin/env julia
# The site of the review: one page, the notebook itself.
#
#     julia --project=docs docs/app.jl dev      # local server with hot reload
#     julia --project=docs docs/app.jl build    # the static site, in docs/dist
#
# Built with Therapy.jl (https://github.com/GroupTherapyOrg/Therapy.jl): the page is
# src/routes/index.jl, its parts are in src/components/, its stylesheet is input.css. The notebook
# is not rendered here. It is the committed export in docs/notebook-static/, which
# docs/render_notebook.sh makes and docs/verify_notebook_export.py checks.
#
# Ported from docs/app.jl of BasisSimulator.jl (MIT, MolloiLab), reduced to one page.

if !haskey(ENV, "JULIA_PROJECT")
    using Pkg
    Pkg.activate(@__DIR__)
end

using Therapy

cd(@__DIR__)

const IS_BUILD = length(ARGS) > 0 && ARGS[1] == "build"

# The base path of every link and asset. A build is served by GitHub Pages at
# https://molloilab.github.io/MaterialDecompositionReview/; the dev server is at the root. A host
# that serves the site elsewhere says where in SNAPSHOT_BASE_PATH (Snapshot does).
ENV["MDREVIEW_BASE"] = get(
    ENV,
    "SNAPSHOT_BASE_PATH",
    IS_BUILD ? "/MaterialDecompositionReview" : "",
)

app = App(;
    routes_dir = "src/routes",
    components_dir = "src/components",
    title = "Material Decomposition in CT",
    output_dir = "dist",
    base_path = ENV["MDREVIEW_BASE"],
    layout = :Layout,
)

# The notebook's export is served beside the page: the fragment loads its WebAssembly islands
# from /notebook-static/material_decomposition.islands/.
Therapy.staticfiles(app, joinpath(@__DIR__, "notebook-static"), "notebook-static")

Therapy.run(app)

# After a build: give the page its description and icon, give the stylesheet a URL that changes
# with every deployment (so a cached sheet never meets newer HTML), and drop what the browser
# never loads. The fragment is already inside index.html; the compiler's report and coverage
# files are for review, not for publication.
if IS_BUILD && isdir(app.output_dir)
    base = ENV["MDREVIEW_BASE"]
    version = get(ENV, "GITHUB_RUN_ID", get(ENV, "GITHUB_SHA", "local"))
    icon = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='8' fill='%232a2520'/%3E%3Ccircle cx='13' cy='16' r='7' fill='%237c3aed'/%3E%3Ccircle cx='20' cy='16' r='7' fill='%230891b2' fill-opacity='.85'/%3E%3C/svg%3E"
    head = """
        <meta name="description" content="An interactive review of material decomposition in computed tomography: one notebook, with every figure and number computed in the open.">
        <link rel="icon" href="$(icon)">
    </head>"""
    for (root, _, files) in walkdir(app.output_dir), f in files
        path = joinpath(root, f)
        if endswith(root, ".islands") && f in ("report.json", "coverage.json")
            rm(path)
        elseif endswith(f, ".fragment.html")
            rm(path)
        elseif endswith(f, ".html")
            html = replace(read(path, String), "</head>" => head; count = 1)
            html = replace(
                html,
                "href=\"$(base)/styles.css\"" => "href=\"$(base)/styles.css?v=$(version)\"";
                count = 1,
            )
            write(path, html)
        end
    end
end
