#!/usr/bin/env julia
# Render notebooks/material_decomposition.jl to docs/notebook-static/: the notebook's cells as
# plain HTML (`material_decomposition.fragment.html`, embedded in the page by docs/app.jl) and its
# `@bind` groups as WebAssembly islands (`material_decomposition.islands/`), through Snapshot.jl.
#
# The export is rendered on a workstation and committed. CI never renders: it recomputes the
# fingerprint below (docs/verify_notebook_export.py) and refuses a stale or broken export.
#
#     docs/render_notebook.sh            # render if stale, then verify (the usual entry point)
#     docs/render_notebook.sh --force    # render whether stale or not
#     julia +1.12 --project=docs/build_env docs/export_notebook.jl [--force | --stale]
#
# Julia 1.12 only: under 1.13 the island compiler compiles nothing for some sliders.
#
# Ported from docs/extract_all.jl of BasisSimulator.jl (MIT, MolloiLab), reduced to one notebook.

import Pkg
let build_env = joinpath(@__DIR__, "build_env")
    if Base.active_project() != joinpath(build_env, "Project.toml")
        Pkg.activate(build_env; io = devnull)
    end
end

using Pluto
using Snapshot: Snapshot, export_notebook
using SHA: bytes2hex, sha256

const ROOT = dirname(@__DIR__)
const SLUG = "material_decomposition"
const NOTEBOOK = joinpath(ROOT, "notebooks", "$(SLUG).jl")
const STATIC_OUT = joinpath(@__DIR__, "notebook-static")
const FRAGMENT = joinpath(STATIC_OUT, "$(SLUG).fragment.html")
const ROOT_LOCK = joinpath(ROOT, "Manifest-v1.12.toml")
const BUILD_LOCK = joinpath(@__DIR__, "build_env", "Manifest.toml")
const HASH_MARK = "mdreview-export-fingerprint"
# The page's asset URLs carry this placeholder; docs/app.jl replaces it with the site's base path.
const ASSETS_BASE = "__MDREVIEW_NOTEBOOK_BASE__"

# How the export is made. The verifier reads this line, so it has one definition. A change to how
# the page renders bumps the version. `forced-fallback=` lists, comma-separated, the `@bind` names
# that are published as static output with a disabled control instead of an island: sliders that
# drive simulations WebAssembly cannot run. Every other `@bind` must compile.
const EXPORT_CONTRACT = "mdreview-lean-v1|therapy|fragment|deps=host|islands|verify|optimize=size|forced-fallback="

const FORCE_FALLBACK_BONDS = Tuple(
    Symbol.(split(
        last(split(EXPORT_CONTRACT, "forced-fallback=")),
        ",";
        keepempty = false,
    )),
)

hash_file(path) = bytes2hex(sha256(read(path)))

"""
What decides the export: the notebook (all of the review's code lives in it), the environment it
runs in (the root `Manifest-v1.12.toml`), the exporter's environment
(`docs/build_env/Manifest.toml`), and `EXPORT_CONTRACT`. `export_fingerprint` in
docs/verify_notebook_export.py computes the same value.
"""
function export_fingerprint()
    parts = (
        hash_file(NOTEBOOK),
        hash_file(ROOT_LOCK),
        hash_file(BUILD_LOCK),
        EXPORT_CONTRACT,
    )
    return bytes2hex(sha256(join(parts, '\0')))
end

"The fingerprint recorded in the committed fragment, or `nothing`."
function recorded_fingerprint()
    isfile(FRAGMENT) || return nothing
    m = match(Regex("<!-- $(HASH_MARK): ([0-9a-f]{64}) -->"), read(FRAGMENT, String))
    return m === nothing ? nothing : String(m[1])
end

is_stale() = recorded_fingerprint() != export_fingerprint()

"""
Transcode every embedded PNG over about 200 KB to WebP at quality 90, which is about a tenth of
the size for a retina CairoMakie figure. Needs `python3` with Pillow; without them the page keeps
its PNGs.
"""
function compress_page_images!(path)
    py = raw"""
    import re, base64, io, sys
    from PIL import Image
    p = sys.argv[1]
    h = open(p, encoding='utf-8', errors='surrogateescape').read()
    def sub(m):
        raw = base64.b64decode(m.group(1))
        if len(raw) < 200_000: return m.group(0)
        out = io.BytesIO()
        Image.open(io.BytesIO(raw)).convert('RGB').save(out, 'WEBP', quality=90, method=6)
        if out.tell() >= len(raw): return m.group(0)
        return 'data:image/webp;base64,' + base64.b64encode(out.getvalue()).decode()
    h2 = re.sub(r'data:image/png;base64,\s*([A-Za-z0-9+/=]{1000,})', sub, h)
    if h2 != h:
        open(p, 'w', encoding='utf-8', errors='surrogateescape').write(h2)
    """
    success(pipeline(ignorestatus(`python3 -c $py $path`); stderr = devnull)) ||
        @warn "figures were not compressed (python3 with Pillow is missing)"
    return nothing
end

# Pluto must not rewrite the notebook while it renders: the fingerprint hashes its bytes.
const SESSION = Pluto.ServerSession(; options = Pluto.Configuration.from_flat_kwargs(;
    disable_writing_notebook_files = true,
))

# Whether a cell's values are baked into the islands as constants, remembered per cell: asking
# fetches the values from the notebook's process.
const IS_CONSTANT = Dict{Pluto.Cell, Bool}()

"""
The cells whose code an island needs for `cell`, in running order.

For every cell an island redraws, Snapshot compiles the code of every cell upstream of it, and
replaces a cell whose values are plain constants (numbers, strings, tuples of them) by those
values. Snapshot 0.2.1 still gathers the cells behind such a constant, so a table the notebook
computes with the simulator drags the simulator into the WebAssembly compiler, which does not
return. This walk stops at a constant. What the notebook computes when it is rendered can then
feed an island, as long as it is stored as a tuple of plain numbers.

It replaces Snapshot's own method of the same name. Remove it once Snapshot stops at constants.
"""
function Snapshot._upstream_closure(topology, cell::Pluto.Cell)
    explorer = Snapshot.PlutoDependencyExplorer
    notebook = only(values(SESSION.notebooks))
    binds = filter(Snapshot.is_bind_cell, notebook.cells)
    reactive = union(Set(binds), Pluto.MoreAnalysis.downstream_recursive(topology, binds))
    is_constant(c) = get!(IS_CONSTANT, c) do
        !(c in reactive) &&
            Snapshot._try_bake_cell(SESSION, notebook, c, topology) !== nothing
    end
    seen = Set{Pluto.Cell}()
    frontier = [cell]
    while !isempty(frontier)
        c = pop!(frontier)
        for up in explorer.where_assigned(topology, topology.nodes[c].references)
            (up === cell || up in seen || Snapshot.is_bind_cell(up)) && continue
            push!(seen, up)
            is_constant(up) || push!(frontier, up)
        end
    end
    order = explorer.topological_order(topology, collect(seen))
    return [c for c in order.runnable if c in seen]
end

"A public export must not name the machine that rendered it."
function assert_no_local_paths(dir)
    places = [homedir(), ROOT, DEPOT_PATH...]
    needles = unique(vcat(places, [realpath(p) for p in places if ispath(p)]))
    files = [joinpath(d, f) for (d, _, fs) in walkdir(dir) for f in fs]
    for file in filter(f -> !endswith(f, ".wasm"), files), needle in needles
        occursin(needle, read(file, String)) &&
            error(
                "$(basename(file)) names this machine ($(needle)); fix the notebook and render again",
            )
    end
    return nothing
end

"""
Run the notebook and write its export. Snapshot opens the notebook in a Pluto session, runs every
cell, renders the outputs, compiles each `@bind` group to WebAssembly and checks the compiled cells
against the notebook's own output. A group that cannot compile is published as static output
under a visible note, and the verifier then refuses the export.
"""
function render()
    VERSION.minor == 12 ||
        error("render with Julia 1.12 (`julia +1.12`); this is Julia $(VERSION)")
    isfile(NOTEBOOK) || error("no notebook at $(relpath(NOTEBOOK, ROOT))")
    isfile(ROOT_LOCK) ||
        error(
            "no Manifest-v1.12.toml at the repository root; docs/render_notebook.sh makes it",
        )
    # Render beside the committed export and replace it only once the new one is whole.
    out = mktempdir(@__DIR__; prefix = "notebook-static.")
    t0 = time()
    page = export_notebook(NOTEBOOK;
        output_dir = out,
        therapy = true, # rendered cells and islands, no Pluto frontend
        fragment = true, # the scoped fragment the site embeds, no iframe
        fragment_dependencies = :host, # the site loads KaTeX and supplies the theme tokens
        assets_base = ASSETS_BASE,
        islands = true,
        verify = true,
        optimize = :size,
        force_fallback_bonds = FORCE_FALLBACK_BONDS,
        env_dir = ROOT, # the notebook's imports resolve from the root environment
        session = SESSION,
    )
    rm(page) # the standalone page: the site embeds the fragment
    fragment = joinpath(out, basename(FRAGMENT))
    isfile(fragment) || error("Snapshot did not write $(basename(FRAGMENT))")
    compress_page_images!(fragment)
    write(
        fragment,
        "<!-- $(HASH_MARK): $(export_fingerprint()) -->\n" * read(fragment, String),
    )
    assert_no_local_paths(out)
    rm(STATIC_OUT; recursive = true, force = true)
    mv(out, STATIC_OUT)
    chmod(STATIC_OUT, 0o755)
    kb = round(Int, filesize(FRAGMENT) / 1024)
    println("rendered $(SLUG) in $(round(Int, time() - t0)) s: fragment $(kb) KB")
    return nothing
end

if abspath(PROGRAM_FILE) == @__FILE__
    if ARGS == ["--stale"]
        println(is_stale() ? "stale" : "current")
    elseif ARGS == ["--force"] || (isempty(ARGS) && is_stale())
        render()
    elseif isempty(ARGS)
        println("the export of $(SLUG) is current")
    else
        error("usage: export_notebook.jl [--force | --stale]")
    end
end
