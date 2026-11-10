# Blueprint: the review, its one notebook, and its page

Written 2026-11-10, at the start of the project. Everything marked **DEFAULT** is a choice made so the
work could start, and is open to change. `Open decisions` at the end lists the ones that matter most.

## 1. The project in one paragraph

Material decomposition is the step that turns the energy dependence of CT measurements into amounts of
materials. Fifty years of methods now cover two-material, three-material, multi-material, single-energy,
probabilistic, and learned decomposition, in the projection domain, in the image domain, and in both at
once. They are usually reviewed by application or by scanner. This review describes all of them as answers
to three questions about one measurement model, selects one representative published method for each
class, and runs every representative method on the same simulated scans of `BasisSimulator.jl`. The model
for its rigor is the photon-counting detector primer of Chen, Lai, and Li (Med. Phys. 53(8):e70586, 2026),
which organizes detector physics around a single causal chain. Here the organizing object is the
measurement model and the count of what it determines.

## 2. One notebook, one page, one paper

```
notebooks/material_decomposition.jl   the walk-through and the source of every method, figure, and number
        │
        ├── results/*.csv             every number the paper states (key, value, unit, note)
        ├── paper/figures/*.pdf       every figure of the paper
        └── docs/                     the notebook exported as one interactive page (GitHub Pages)

paper/make_values.py        results/*.csv  ->  paper/values.tex  (the \V{key} macros)
paper/make_references.py    LITERATURE.md  ->  the reference list of paper/main_clean.tex, by first citation
paper/main_clean.tex        the manuscript, the only hand-edited paper file
```

All code lives in the notebook. There is no `src/` and no module. A method is written once, in the
part of the notebook that explains it, and the benchmark part at the end calls the same definitions.

## 3. Contributions, in the order the paper delivers them

1. A common measurement model and notation for every class of decomposition.
2. A taxonomy by three questions: where the model is inverted, what closes the system, and how the answer
   is reported.
3. A review of each class against that model, with one representative method described in full.
4. An open implementation of every representative method on the same simulated scans, in one interactive
   notebook.

The same order holds in the abstract, the Introduction, the sections, the Discussion, and the Conclusion.

## 4. The taxonomy

### The measurement model (one for every method)

A ray has `K` spectral measurements. A voxel is described by `M` basis materials. Measurement `k` has the
expected value `λ_k = ∫ S_k(E) exp(−Σ_m f_m(E) a_m) dE`, where `a_m` is the line integral of the density of
material `m`, `f_m(E)` its mass attenuation coefficient, and `S_k(E)` the spectral response of the
measurement (source spectrum, filtration, detector response). The acquisition mechanism enters only through
`S_k(E)`. This is the notation of `BasisSimulator.jl` (`spectral_basis`, `decompose_nchannel`).

### Question 1: where is the model inverted?

| Class | Inverts | Needs | Typical weakness |
|---|---|---|---|
| Projection domain | each ray, before reconstruction | the `K` measurements on the same ray path, and `S_k(E)` or a calibration | noise amplification, no spatial prior |
| Image domain | each voxel, after `K` reconstructions | `K` images and effective attenuations | beam hardening stays in the images |
| One-step (joint) | all rays and voxels together | raw data, a system model, a regularizer | cost and tuning |

### Question 2: what closes the system? (the counting ladder)

Materials without a K-edge in the detected spectrum span close to two energy functions (Alvarez and
Macovski 1976), and each K-edge material adds one. `K` measurements can determine at most `K` amounts in a
voxel, and no more than the number of energy functions its materials span. The conservation of volume adds
one. Everything above
that needs information from outside the voxel's own measurements. The first part of the notebook computes
each of these numbers.

| Rung | Measurements `K` | Materials per voxel | Materials per image | Closure | Representative |
|---|---|---|---|---|---|
| A. Two-basis | 2 | 2 | 2 | none needed | Alvarez and Macovski 1976 |
| B. Two-basis, more measurements | > 2 | 2 | 2 | statistical weighting | Black et al. 2026 |
| C. K-edge | ≥ 3 | 3 or more | 3 or more | none needed | Roessl and Proksa 2007 |
| D. Three-material | 2 | 3 | 3 | conservation of volume or mass | Liu et al. 2009 |
| E. Multi-material | 2 | ≤ 3 | > 3 | a library of triplets, one selected per voxel | Mendonça et al. 2014 |
| F. Regularized multi-material | 2 | ≤ 3 | > 3 | a spatial or sparsity penalty beside the library | Long and Fessler 2014, Xue et al. 2017 |
| G. Single-energy | 1 | 2 | > 2 | conservation of volume and a selected pair | Xue et al. 2021 |

### Question 3: how is the answer reported?

| Estimator | Reports | Examples |
|---|---|---|
| Calibration (polynomial, table) | a point estimate | Lehmann et al. 1981, Stenner et al. 2007, Alvarez 2011 |
| Maximum likelihood per ray or voxel | a point estimate near the noise bound | Roessl and Proksa 2007, Cong et al. 2022, Black et al. 2026 |
| Penalized likelihood | a regularized point estimate | Niu et al. 2014, Long and Fessler 2014, Mechlem et al. 2018 |
| Rule on a library | a point estimate after a selection | Mendonça et al. 2014, Xue et al. 2021 |
| Posterior | probabilities and an uncertainty | Lalonde et al. 2017, Beikali Soltani and Bouchard 2024, Jiang et al. 2025 |
| Learned | a network's estimate | see below |

### Learned methods, by where the physics enters

| Class | Physics enters | Labels from | Examples |
|---|---|---|---|
| Supervised network ("neural") | nowhere | a dual-energy decomposition, or simulation | Zhang et al. 2019, Clark et al. 2018 |
| Physics-informed network ("PINN") | the loss | simulation, or none | Lyu et al. 2021, Peng et al. 2024 |
| Unrolled or model-based network | the architecture | simulation | to be surveyed (LITERATURE.md, "Still to read") |
| Fitted at test time | the output | none | Wu et al. 2025, Hellwege et al. 2026, Jiang et al. 2025 |

Every example above is a verified record in LITERATURE.md. A class is stated in the paper only after its
papers have been read.

### Math and notation

As little math as the argument needs. The simplest form of a method is the one shown, because it explains
best. No new notation: each class is written in the symbols of the papers it comes from, and the text says
which. The measurement model follows Alvarez and Macovski 1976 and Lehmann et al. 1981 as written in Black
et al. 2026. The mixture model of the image-domain classes follows Mendonça et al. 2014 and Xue et al. 2021
(volume fractions that sum to one). Where two literatures use one symbol for two things, the paper keeps
the older use and says so once.

## 5. Representative methods (one per class)

**DEFAULT.** Each class is represented by a published method that anyone can check against its paper.

| # | Class | Representative | Code |
|---|---|---|---|
| 1 | Projection domain | nested profile likelihood (Black et al. 2026), beside Cong et al. 2022 | in `BasisSimulator.jl` (`decompose_nchannel`, `decompose_cong`) |
| 2 | Image domain, two materials | linear inversion with precorrection, Maaß et al. 2009 | to write |
| 3 | One-step | penalized likelihood, Long and Fessler 2014 or Mechlem et al. 2018 | to write (Open 2) |
| 4 | Three materials | Liu et al. 2009 | to write, closed form |
| 5 | Multi-material | Mendonça et al. 2014 | to write |
| 6 | Single energy | Xue et al. 2021 | to write |
| 7 | Probabilistic | a published Bayesian method (Open 3) | to write |
| 8 | Neural | a supervised network trained on simulated labels | to write and train |
| 9 | Physics-informed | MD-CNN of Lyu et al. 2021 (Open 3) | to write and train |

## 6. Structure of the paper, with the part of the notebook behind each section

| § | Section | Its one point | Figures and tables |
|---|---|---|---|
| 1 | Introduction | many methods, no common framework, no common test | Fig. 1 (publications per year) |
| 2 | A common measurement model | one model, three questions, a count of what is determined | Fig. 2 (the chain and the three questions), Table 1 (the ladder) |
| 3 | How the measurements are made | the acquisition sets `K` and the conditioning | spectra and bounds per system |
| 4 | Projection-domain decomposition | the polychromatic model per ray, noise near the bound | bias and noise against the bound |
| 5 | Image-domain decomposition | simple and general, beam hardening remains | bias against path length |
| 6 | One-step decomposition | physics and a spatial prior together, at a cost | maps against iterations |
| 7 | Beyond two materials | conservation, libraries, and their sensitivity | triangles in the two-energy plane |
| 8 | Single-energy decomposition | one equation, so assumptions determine the answer | pairs against CT number |
| 9 | Probabilistic decomposition | the ambiguity kept and reported | posterior and coverage |
| 10 | Learned decomposition | what is learned depends on the labels and on where the physics enters | error inside and outside the training data |
| 11 | What decomposition is used for | VMI, VNC, iodine, electron density | one figure |
| 12 | A common benchmark | every representative method on the same scans | the benchmark table |
| 13 | Discussion, open problems, Conclusion | what the framework predicts and what is unsolved | none |

The notebook has one part per section, in this order. Two parts exist: the measurement model, and a
first inversion of one ray in the projection domain and with the linear model of the image domain.

## 7. The notebook

It follows the example notebooks of `BasisSimulator.jl`: a title and one bold lead sentence, a locator band,
"The Chain at a Glance" with a drawn flow chart, numbered parts with an illustration above the main plots,
Title Case in figures, fixed seeds, only numbers the notebook computes, and a closing table of checks. Cells
are stored in dependency order, so the notebook also runs headless as a script.

**DEFAULT** scanners for the later parts: the GE Revolution Apex (rapid kVp switching, `K = 2`) and the
Siemens NAEOTOM Alpha (photon counting, `K = 4`), both modeled in `BasisSimulator.jl`. **DEFAULT** phantoms:
the Gammex 472, rod layouts, and one XCAT chest section.

## 8. The page

`docs/` holds a single-page site: the notebook, exported with its interactive parts compiled to
WebAssembly, in a quiet reading layout with a light and dark theme. GitHub Actions build it and publish
it to GitHub Pages. The export is rendered locally and committed, because later parts of the notebook need
a GPU.

## 9. Order of work

1. The open decisions below.
2. The literature: read the reviews and the classes marked "Still to read" in LITERATURE.md, verify each
   entry, and fix the list of surveyed methods.
3. The acquisition, projection-domain, and image-domain parts (they need only `BasisSimulator.jl`).
4. The closed-form methods: three-material, multi-material, single-energy.
5. The one-step method, the probabilistic method, and the two networks.
6. The benchmark part.
7. Introduction, Discussion, and abstract, last. Then four independent reviews of the manuscript
   (technical, clinical, broad-interest, and style), merged into one plan.

## Open decisions

1. **Venue and article type.** Medical Physics, where the primer appeared, or a review in Nature Medicine.
   The two ask for different papers: Medical Physics takes the full technical review, and Nature Medicine a
   shorter one for clinical readers with few equations. Until the venue is fixed the manuscript targets
   none: `main_clean.tex` is in the generic style and is the arXiv version, and a journal layout is only
   ever generated from it by `paper/make_<venue>.py`, with the text unchanged. Check each journal's
   current instructions for review articles first, including whether it takes unsolicited reviews.
2. **The one-step representative.** Long and Fessler 2014 is the multi-material one, Mechlem et al. 2018
   the photon-counting one.
3. **The probabilistic and physics-informed representatives.** Candidates are Lalonde et al. 2017 or
   Beikali Soltani and Bouchard 2024, and Lyu et al. 2021.
4. **Scope.** DEFAULT: K-edge decomposition is a rung of the ladder with one short subsection and no
   simulation. Applications (VMI, VNC, iodine, electron density) are one section. Dual-layer detectors are
   described but not simulated, because `BasisSimulator.jl` has no dual-layer model.
5. **Title and authors.** The working title is in `paper/main_clean.tex`.
