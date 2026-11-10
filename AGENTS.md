# MaterialDecompositionReview

One review, one notebook, one page. Read `BLUEPRINT.md` first: it holds the taxonomy, the structure of the
paper, the representative methods, and the open decisions. `LITERATURE.md` holds every reference.

## The flow

`notebooks/material_decomposition.jl` → `results/*.csv` and `paper/figures/` → `paper/values.tex` →
`paper/main_clean.tex`. The notebook is also exported to the page in `docs/`.

- **All code lives in the notebook.** A method is written once, in the part that explains it. Do not add a
  `src/`, a module, or an include chain.
- **Use the simulator, never a copy of it.** Spectra, cross sections, scanners, phantoms, projection, and
  reconstruction come from `BasisSimulator.jl` (imported as `BS`; `XrayAttenuation` is `BS.XA`; CairoMakie
  is `Mke`).
- **Cells are stored in dependency order**, so the file runs headless as a script
  (`julia --project=. notebooks/material_decomposition.jl`). Keep it that way when adding cells, and keep
  the `# ╔═╡ Cell order:` block in step with the cells.
- Fixed seeds. No machine paths printed. Only numbers the notebook computes are stated. Computed tables go
  through `Markdown.parse`. Figure text is in Title Case.
- The notebook ends each part with what it wrote to `results/`, and ends with a table of checks.

## The paper

- `paper/main_clean.tex` is the only hand-edited paper file, in a generic style, and is the arXiv version.
  No journal is targeted in it. A journal layout is generated from it later, with the text unchanged.
- Every number is a `\V{key}` from `values.tex` (`python3 paper/make_values.py`). Never type a number.
- The reference list is generated (`python3 paper/make_references.py`) from `LITERATURE.md`. Never add a
  reference by hand or from memory: print it with `python3 scripts/crossref.py key=doi`, add it to
  `LITERATURE.md`, and read the paper before a sentence attributes a result to it.
- **Math and notation.** As little math as the argument needs. Show the simplest form of a method. Do not
  invent notation: write each class in the symbols of the papers it comes from, and say which.
- **Voice.** Plain sentences, one idea each, each following from the one before. Measured wording ("can be
  used to", "can help"). No semicolons. "We" at most twice. Never "novel", "first" as a claim, "match",
  "validate" beyond what was measured, "suggest", "might", "i.e.", "e.g.". Results as numbers. Every method
  is described fairly in its authors' terms before it is compared.
- A red `\outline{}` is the plan of a section still to write, and a red `\pending{}` an open item.

## Formatting and checks

Fatou formats and lints the Julia code (`fatou.toml`), and `docs/fatou.jl` formats the notebook cell by
cell. CI checks both. Before a commit: run the notebook headless, `python3 paper/make_values.py`,
`python3 paper/make_references.py`, and compile the paper with no undefined reference or citation.

## What does not belong here

The repository is public. Only published methods and published results are described or implemented.
Unpublished work, patient data, checkpoints, and anything under a license that forbids redistribution
(the XCAT phantoms, for example) are never committed.
