# Material Decomposition in CT: a review in one notebook

A review of material decomposition in computed tomography, from two basis materials to multi-material,
single-energy, probabilistic, and learned methods. Every class is described as an answer to three questions
about one measurement model, and one representative method of each class is run on the same simulated scans.

**Read it as an interactive page: <https://molloilab.github.io/MaterialDecompositionReview>**

The project is at its start. The first part of the notebook, the measurement model, exists. The parts on the
methods and the manuscript are being written. `BLUEPRINT.md` is the plan.

## How the repository works

One Pluto notebook is the walk-through and the source of every method, figure, and number.

```
notebooks/material_decomposition.jl   the notebook: every method, written out and run
results/                              every number the paper states, written by the notebook (CSV)
paper/                                the manuscript
  main_clean.tex                        the only hand-edited paper file (generic style, the arXiv version)
  make_values.py                        results/*.csv -> values.tex, the \V{key} numbers
  make_references.py                    LITERATURE.md -> the reference list, in order of first citation
  figures/                              written by the notebook
docs/                                 the notebook as one interactive page (Therapy.jl, GitHub Pages)
scripts/                              the literature census and the reference check
LITERATURE.md                         every reference, verified against Crossref or arXiv
BLUEPRINT.md                          the design: the taxonomy, the sections, the order of work
```

All code lives in the notebook. There is no `src/` and no module.

## Run it

Julia 1.12 or later.

```
julia --project=. -e 'import Pkg; Pkg.instantiate()'
julia --project=. notebooks/material_decomposition.jl      # headless: writes results/ and paper/figures/
```

The notebook is an ordinary [Pluto](https://plutojl.org) notebook and can be opened in Pluto to change it
interactively. The simulator is [`BasisSimulator.jl`](https://github.com/MolloiLab/BasisSimulator.jl).

## Build the paper

```
python3 paper/make_values.py
python3 paper/make_references.py
cd paper && tectonic main_clean.tex
```

No number in the manuscript is typed by hand, and no reference is added from memory.
`python3 scripts/crossref.py key=doi` prints a reference from its Crossref record for `LITERATURE.md`.

## Build the page

The page is the notebook, exported with its interactive cells compiled to WebAssembly and set in a single
[Therapy.jl](https://github.com/GroupTherapyOrg/Therapy.jl) page. The export is rendered locally and
committed, and GitHub Actions build and publish the site.

```
docs/render_notebook.sh        # run the notebook and export it to docs/notebook-static/ (Julia 1.12)
docs/build.sh                  # build the site into docs/dist/
julia docs/fatou.jl --write    # format the notebook's cells
```

A cell that follows a slider runs in the browser, so it uses plain Julia and WasmMakie only. Anything that
needs the simulator is computed when the notebook is rendered and passed on as a tuple of numbers.

## Citing

The manuscript is in preparation. Until it is posted, please cite this repository and
`BasisSimulator.jl` (Black, Khodajou-Chokami, and Molloi, *SoftwareX* 35:102910, 2026).

## License

The code is released under the MIT license (`LICENSE`). The text and figures of the manuscript in `paper/`
are not covered by it and remain with their authors until the paper is published.
