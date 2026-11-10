# The notebook itself: Snapshot's fragment (docs/notebook-static/, written by
# docs/export_notebook.jl) placed in the page as ordinary DOM, with no iframe. The fragment scopes
# its own stylesheet (`@scope (.snap-notebook)`) and loads its WebAssembly islands from the
# `.islands/` folder beside it.
#
# Ported from docs/src/components/NotebookPage.jl of BasisSimulator.jl (MIT, MolloiLab).

const NOTEBOOK_STATIC = normpath(joinpath(@__DIR__, "..", "..", "notebook-static"))
const NOTEBOOK_SLUG = "material_decomposition"

"The exported fragment, its asset URLs pointed at this site."
function notebook_html()
    path = joinpath(NOTEBOOK_STATIC, "$(NOTEBOOK_SLUG).fragment.html")
    isfile(path) ||
        error("no notebook export in docs/notebook-static/: run docs/render_notebook.sh")
    return replace(
        read(path, String),
        "__MDREVIEW_NOTEBOOK_BASE__" => "$(BASE)/notebook-static",
    )
end

"The notebook's sections for the table of contents: `(id, label, depth)` of every `h2` and `h3`."
function notebook_sections(html::AbstractString)
    unescape(s) = replace(
        s,
        r"&#(\d+);" => m -> string(Char(parse(Int, m[3:(end - 1)]))),
        "&amp;" => "&",
        "&lt;" => "<",
        "&gt;" => ">",
        "&quot;" => "\"",
    )
    return [
        (unescape(m[2]), unescape(strip(replace(m[3], r"<[^>]+>" => ""))), parse(Int, m[1]))
        for m in eachmatch(r"<h([23])\b[^>]*\bid=\"([^\"]+)\"[^>]*>(.*?)</h\1>"s, html)
    ]
end

"How many cells recompute in the browser, from the island compiler's summary."
function interactive_cells()
    path = joinpath(NOTEBOOK_STATIC, "$(NOTEBOOK_SLUG).islands", "coverage.json")
    isfile(path) || return 0
    m = match(r"\"interactive\"\s*:\s*(\d+)", read(path, String))
    return m === nothing ? 0 : parse(Int, m[1])
end

"The page: a line of facts, then the notebook in its sheet, beside the table of contents."
function NotebookPage()
    html = notebook_html()
    n = interactive_cells()
    return Div(
        :class =>
            "max-w-[76rem] mx-auto xl:grid xl:grid-cols-[minmax(0,1fr)_14rem] xl:gap-10",
        Div(
            :class => "min-w-0 max-w-[58rem] w-full mx-auto",
            Div(
                :class =>
                    "mdr-meta flex flex-wrap items-center justify-between gap-x-6 gap-y-1 px-2 pb-3",
                Span(
                    n == 0 ?
                        "A Pluto notebook" :
                        Fragment(
                            Span(:class => "mdr-dot mr-2", Symbol("aria-hidden") => "true"),
                            "A Pluto notebook. $(n) $(n == 1 ? "cell recomputes" : "cells recompute") in your browser as you move the sliders.",
                        ),
                ),
                A(
                    :href => NOTEBOOK_URL,
                    :target => "_blank",
                    :rel => "noopener",
                    "Notebook source (.jl)",
                ),
            ),
            Article(
                :class => "mdr-sheet px-5 sm:px-10 lg:px-14 py-8 sm:py-12",
                RawHtml(html),
            ),
        ),
        TableOfContents(notebook_sections(html)),
    )
end
