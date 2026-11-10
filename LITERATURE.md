# Literature

The record of what the review cites, where each entry goes, and how it was verified. Started 2026-11-10.

**Rule: no reference enters this file or the paper from memory.** An entry is printed by
`python3 scripts/crossref.py key=doi` from the publisher's Crossref record, or checked against the arXiv
record. `paper/make_references.py` then builds the reference list of the manuscript from this file, in order
of first citation, and stops on a citation key that is not here. A sentence that attributes a result to a
source is written only after that source has been read. `\pending{...}` marks a field Crossref does not hold.

## What exists so far

- **73 entries verified against Crossref and 3 against arXiv on 2026-11-10** (below). Each identifier was
  resolved, and its title, authors, journal, volume, and year were read back.
- Verified means the record. Most of these papers have **not** yet been read for this review, so none of
  them supports a claim in the manuscript until it has been.
- The photon-counting detector primer that sets the standard of rigor is `chen2026primer`.

## The census (Fig. 1)

`scripts/literature_census.py` counts PubMed records for each year from 1976 to 2025 and writes
`results/literature_census.csv`, with its queries and the date of the run in the last lines of the file.
`paper/make_values.py` turns the totals into `\V{census-*}` keys. The counts are of PubMed records that name
material or basis decomposition with CT in the title or abstract. They leave out conference papers and
engineering journals that PubMed does not index, which the paper states.

## Where each entry goes

| Section | Keys |
|---|---|
| 1 Introduction, reviews and scope | `mccollough2015`, `mccollough2020tg291`, `patino2016`, `willemink2018`, `taguchi2013`, `danielsson2021`, `chen2026primer`, `bousse2024review` |
| 2 Measurement model | `alvarez1976`, `lehmann1981`, `brooks1977`, `kelcz1979`, `roessl2009crlb`, `blackprojection`, `paterno2020` |
| 3 Acquisition | `kalender1986`, `flohr2006`, `johnson2007`, `rajendran2022`, `mccollough2023` |
| 4 Projection domain | `stenner2007`, `alvarez2011`, `zimmerman2015`, `ducros2017`, `cong2022`, `roessl2007`, `schlomka2008`, `blackprojection` |
| 5 Image domain | `maass2009`, `niu2014`, `yu2012vmi` |
| 6 One-step | `fessler2002`, `elbakri2002`, `long2014`, `barber2016`, `schmidt2017`, `mechlem2018`, `mory2018`, `tilley2019` |
| 7 Beyond two materials | `liu2009`, `mendonca2014`, `xue2017`, `ding2018`, `li2020multra`, `khodajou2026`, `jadick2024triplet`, `phillips2025nonunique` |
| 8 Single energy | `xue2020`, `xue2021`, `chen2025multibasis` |
| 9 Probabilistic | `lalonde2017bayes`, `soltani2024bayesvnc`, `jiang2025` |
| 10 Learned | `clark2018`, `zhang2019butterfly`, `gong2023bdtcnn`, `lyu2021mdcnn`, `peng2024fidelity`, `valand2026physics`, `fujiwara2022virtualct`, `rajagopal2025`, `liu2026mmdx`, `liu2024nolmbmi`, `zhao2020psb`, `cong2020vmi`, `zhang2026vmi`, `li2023enchroma`, `wu2025jsover`, `hellwege2026`, `karniadakis2021`, `raissi2019`, `geirhos2020`, `guan2022domain` |
| 12 Benchmark | `basissimulator`, `segars2010`, `dahal2024xcat3`, `abadi2020vit` |

## Still to read (not yet searched or verified)

These are the gaps the first survey left. None of them may be cited until an entry is verified here.

- **Existing reviews of material decomposition.** The census counts the PubMed reviews. Each has to be read
  and grouped, as the primer groups the photon-counting reviews, before the Introduction can state the gap.
- **Unrolled and model-based networks** for decomposition (physics in the architecture). No entry yet.
- **Projection-domain learned decomposition** and learned one-step reconstruction.
- **Supervised networks**: the widely used image-domain networks beyond `clark2018` and `zhang2019butterfly`.
- **Noise in decomposition**: correlated basis noise and its reduction, and bias at low counts.
- **Dual-layer and split-filter acquisition** (described, not simulated).
- **Electron density, effective atomic number, and stopping power** as uses of decomposition.
- **Calibration and photon-counting forward models** beyond the entries below.

## Notes on single entries

- `clark2018`: Crossref lists the authors as Badea, Holbrook, Clark and gives no volume. Confirm the author
  order and the article number on the SPIE page before it is cited.
- `jadick2024triplet`, `gong2023bdtcnn`: SPIE proceedings. Crossref gives a first page, not the article
  number. Confirm on the SPIE page.
- `mccollough2020tg291`, `ducros2017`: Crossref holds no pages. Complete from the publisher's page.
- `fessler2002`: Crossref gives the first page only.
- `johnson2007`, `flohr2006`: the year Crossref gives is the online year. The print years are 2007 and 2006.

## Verified against Crossref on 2026-11-10

```latex
\bibitem{alvarez1976}
R.~E. Alvarez and A. Macovski, ``Energy-selective reconstructions in X-ray computerised tomography,'' \emph{Phys. Med. Biol.}, vol.~21, no.~5, pp. 733--744, 1976, doi: 10.1088/0031-9155/21/5/002.

\bibitem{brooks1977}
R.~A. Brooks, ``A Quantitative Theory of the Hounsfield Unit and Its Application to Dual Energy Scanning,'' \emph{J. Comput. Assist. Tomogr.}, vol.~1, no.~4, pp. 487--493, 1977, doi: 10.1097/00004728-197710000-00016.

\bibitem{kelcz1979}
F. Kelcz, P.~M. Joseph, and S.~K. Hilal, ``Noise considerations in dual energy CT scanning,'' \emph{Med. Phys.}, vol.~6, no.~5, pp. 418--425, 1979, doi: 10.1118/1.594520.

\bibitem{lehmann1981}
L.~A. Lehmann, R.~E. Alvarez, A. Macovski, W.~R. Brody, N.~J. Pelc, S.~J. Riederer, \emph{et al.}, ``Generalized image combinations in dual KVP digital radiography,'' \emph{Med. Phys.}, vol.~8, no.~5, pp. 659--667, 1981, doi: 10.1118/1.595025.

\bibitem{kalender1986}
W.~A. Kalender, W.~H. Perman, J.~R. Vetter, and E. Klotz, ``Evaluation of a prototype dual-energy computed tomographic apparatus. I. Phantom studies,'' \emph{Med. Phys.}, vol.~13, no.~3, pp. 334--339, 1986, doi: 10.1118/1.595958.

\bibitem{flohr2006}
T.~G. Flohr, C.~H. McCollough, H. Bruder, M. Petersilka, K. Gruber, C. S\"uβ, \emph{et al.}, ``First performance evaluation of a dual-source CT (DSCT) system,'' \emph{Eur. Radiol.}, vol.~16, no.~2, pp. 256--268, 2005, doi: 10.1007/s00330-005-2919-2.

\bibitem{johnson2007}
T.~R.~C. Johnson, B. Krau{\ss}, M. Sedlmair, M. Grasruck, H. Bruder, D. Morhard, \emph{et al.}, ``Material differentiation by dual energy CT: initial experience,'' \emph{Eur. Radiol.}, vol.~17, no.~6, pp. 1510--1517, 2006, doi: 10.1007/s00330-006-0517-6.

\bibitem{roessl2007}
E. Roessl and R. Proksa, ``K-edge imaging in x-ray computed tomography using multi-bin photon counting detectors,'' \emph{Phys. Med. Biol.}, vol.~52, no.~15, pp. 4679--4696, 2007, doi: 10.1088/0031-9155/52/15/020.

\bibitem{schlomka2008}
J.~P. Schlomka, E. Roessl, R. Dorscheid, S. Dill, G. Martens, T. Istel, \emph{et al.}, ``Experimental feasibility of multi-energy photon-counting K-edge imaging in pre-clinical computed tomography,'' \emph{Phys. Med. Biol.}, vol.~53, no.~15, pp. 4031--4047, 2008, doi: 10.1088/0031-9155/53/15/002.

\bibitem{roessl2009crlb}
E. Roessl and C. Herrmann, ``Cram\'er--Rao lower bound of basis image noise in multiple-energy x-ray imaging,'' \emph{Phys. Med. Biol.}, vol.~54, no.~5, pp. 1307--1318, 2009, doi: 10.1088/0031-9155/54/5/014.

\bibitem{mccollough2015}
C.~H. McCollough, S. Leng, L. Yu, and J.~G. Fletcher, ``Dual- and Multi-Energy CT: Principles, Technical Approaches, and Clinical Applications,'' \emph{Radiology}, vol.~276, no.~3, pp. 637--653, 2015, doi: 10.1148/radiol.2015142631.

\bibitem{patino2016}
M. Patino, A. Prochowski, M.~D. Agrawal, F.~J. Simeone, R. Gupta, P.~F. Hahn, \emph{et al.}, ``Material Separation Using Dual-Energy CT: Current and Emerging Applications,'' \emph{RadioGraphics}, vol.~36, no.~4, pp. 1087--1105, 2016, doi: 10.1148/rg.2016150220.

\bibitem{mccollough2020tg291}
C.~H. McCollough, K. Boedeker, D. Cody, X. Duan, T. Flohr, S.~S. Halliburton, \emph{et al.}, ``Principles and applications of multienergy CT: Report of AAPM Task Group 291,'' \emph{Med. Phys.}, vol.~47, no.~7, \pending{pages}, 2020, doi: 10.1002/mp.14157.

\bibitem{taguchi2013}
K. Taguchi and J.~S. Iwanczyk, ``Vision 20/20: Single photon counting x-ray detectors in medical imaging,'' \emph{Med. Phys.}, vol.~40, no.~10, p. 100901, 2013, doi: 10.1118/1.4820371.

\bibitem{willemink2018}
M.~J. Willemink, M. Persson, A. Pourmorteza, N.~J. Pelc, and D. Fleischmann, ``Photon-counting CT: Technical Principles and Clinical Prospects,'' \emph{Radiology}, vol.~289, no.~2, pp. 293--312, 2018, doi: 10.1148/radiol.2018172656.

\bibitem{danielsson2021}
M. Danielsson, M. Persson, and M. Sj\"olin, ``Photon-counting x-ray detectors for CT,'' \emph{Phys. Med. Biol.}, vol.~66, no.~3, p. 03TR01, 2021, doi: 10.1088/1361-6560/abc5a5.

\bibitem{chen2026primer}
G.-H. Chen, R. Lai, and K. Li, ``A physics primer on photon-counting detectors in CT: Physics, signal formation, and performance,'' \emph{Med. Phys.}, vol.~53, no.~8, p. e70586, 2026, doi: 10.1002/mp.70586.

\bibitem{yu2012vmi}
L. Yu, S. Leng, and C.~H. McCollough, ``Dual-Energy CT--Based Monochromatic Imaging,'' \emph{Amer. J. Roentgenol.}, vol.~199, no.~5_supplement, pp. S9--S15, 2012, doi: 10.2214/ajr.12.9121.

\bibitem{stenner2007}
P. Stenner, T. Berkus, and M. Kachelriess, ``Empirical dual energy calibration (EDEC) for cone-beam computed tomography,'' \emph{Med. Phys.}, vol.~34, no.~9, pp. 3630--3641, 2007, doi: 10.1118/1.2769104.

\bibitem{alvarez2011}
R.~E. Alvarez, ``Estimator for photon counting energy selective x-ray imaging with multibin pulse height analysis,'' \emph{Med. Phys.}, vol.~38, no.~5, pp. 2324--2334, 2011, doi: 10.1118/1.3570658.

\bibitem{zimmerman2015}
K.~C. Zimmerman and T.~G. Schmidt, ``Experimental comparison of empirical material decomposition methods for spectral CT,'' \emph{Phys. Med. Biol.}, vol.~60, no.~8, pp. 3175--3191, 2015, doi: 10.1088/0031-9155/60/8/3175.

\bibitem{ducros2017}
N. Ducros, J.~F.~P.-J. Abascal, B. Sixou, S. Rit, and F. Peyrin, ``Regularization of nonlinear decomposition of spectral x-ray projection images,'' \emph{Med. Phys.}, vol.~44, no.~9, \pending{pages}, 2017, doi: 10.1002/mp.12283.

\bibitem{cong2022}
W. Cong, B. De Man, and G. Wang, ``Projection decomposition via univariate optimization for dual-energy CT,'' \emph{J. X-Ray Sci. Technol.}, vol.~30, no.~4, pp. 725--736, 2022, doi: 10.3233/xst-221153.

\bibitem{maass2009}
C. Maa{\ss}, M. Baer, and M. Kachelrie{\ss}, ``Image-based dual energy CT using optimized precorrection functions: A practical new approach of material decomposition in image domain,'' \emph{Med. Phys.}, vol.~36, no.~8, pp. 3818--3829, 2009, doi: 10.1118/1.3157235.

\bibitem{niu2014}
T. Niu, X. Dong, M. Petrongolo, and L. Zhu, ``Iterative image-domain decomposition for dual-energy CT,'' \emph{Med. Phys.}, vol.~41, no.~4, p. 041901, 2014, doi: 10.1118/1.4866386.

\bibitem{fessler2002}
J.~A. Fessler, I.~A. Elbakri, P. Sukovic, and N.~H. Clinthorne, ``Maximum-likelihood dual-energy tomographic image reconstruction,'' \emph{Proc. SPIE}, vol.~4684, p. 38, 2002, doi: 10.1117/12.467189.

\bibitem{elbakri2002}
I.~A. Elbakri and J.~A. Fessler, ``Statistical image reconstruction for polyenergetic X-ray computed tomography,'' \emph{IEEE Trans. Med. Imag.}, vol.~21, no.~2, pp. 89--99, 2002, doi: 10.1109/42.993128.

\bibitem{long2014}
Y. Long and J.~A. Fessler, ``Multi-Material Decomposition Using Statistical Image Reconstruction for Spectral CT,'' \emph{IEEE Trans. Med. Imag.}, vol.~33, no.~8, pp. 1614--1626, 2014, doi: 10.1109/tmi.2014.2320284.

\bibitem{barber2016}
R. Foygel Barber, E.~Y. Sidky, T. Gilat Schmidt, and X. Pan, ``An algorithm for constrained one-step inversion of spectral CT data,'' \emph{Phys. Med. Biol.}, vol.~61, no.~10, pp. 3784--3818, 2016, doi: 10.1088/0031-9155/61/10/3784.

\bibitem{schmidt2017}
T.~G. Schmidt, R.~F. Barber, and E.~Y. Sidky, ``A Spectral CT Method to Directly Estimate Basis Material Maps From Experimental Photon-Counting Data,'' \emph{IEEE Trans. Med. Imag.}, vol.~36, no.~9, pp. 1808--1819, 2017, doi: 10.1109/tmi.2017.2696338.

\bibitem{mechlem2018}
K. Mechlem, S. Ehn, T. Sellerer, E. Braig, D. Munzel, F. Pfeiffer, \emph{et al.}, ``Joint Statistical Iterative Material Image Reconstruction for Spectral Computed Tomography Using a Semi-Empirical Forward Model,'' \emph{IEEE Trans. Med. Imag.}, vol.~37, no.~1, pp. 68--80, 2018, doi: 10.1109/tmi.2017.2726687.

\bibitem{mory2018}
C. Mory, B. Sixou, S. Si-Mohamed, L. Boussel, and S. Rit, ``Comparison of five one-step reconstruction algorithms for spectral CT,'' \emph{Phys. Med. Biol.}, vol.~63, no.~23, p. 235001, 2018, doi: 10.1088/1361-6560/aaeaf2.

\bibitem{tilley2019}
S. Tilley, W. Zbijewski, and J.~W. Stayman, ``Model-based material decomposition with a penalized nonlinear least-squares CT reconstruction algorithm,'' \emph{Phys. Med. Biol.}, vol.~64, no.~3, p. 035005, 2019, doi: 10.1088/1361-6560/aaf973.

\bibitem{liu2009}
X. Liu, L. Yu, A.~N. Primak, and C.~H. McCollough, ``Quantitative imaging of element composition and mass fraction using dual-energy CT: Three-material decomposition,'' \emph{Med. Phys.}, vol.~36, no.~5, pp. 1602--1609, 2009, doi: 10.1118/1.3097632.

\bibitem{mendonca2014}
P.~R.~S. Mendonca, P. Lamb, and D.~V. Sahani, ``A Flexible Method for Multi-Material Decomposition of Dual-Energy CT Images,'' \emph{IEEE Trans. Med. Imag.}, vol.~33, no.~1, pp. 99--116, 2014, doi: 10.1109/tmi.2013.2281719.

\bibitem{xue2017}
Y. Xue, R. Ruan, X. Hu, Y. Kuang, J. Wang, Y. Long, \emph{et al.}, ``Statistical image-domain multimaterial decomposition for dual-energy CT,'' \emph{Med. Phys.}, vol.~44, no.~3, pp. 886--901, 2017, doi: 10.1002/mp.12096.

\bibitem{ding2018}
Q. Ding, T. Niu, X. Zhang, and Y. Long, ``Image-domain multimaterial decomposition for dual-energy CT based on prior information of material images,'' \emph{Med. Phys.}, vol.~45, no.~8, pp. 3614--3626, 2018, doi: 10.1002/mp.13001.

\bibitem{li2020multra}
Z. Li, S. Ravishankar, Y. Long, and J.~A. Fessler, ``DECT-MULTRA: Dual-Energy CT Image Decomposition With Learned Mixed Material Models and Efficient Clustering,'' \emph{IEEE Trans. Med. Imag.}, vol.~39, no.~4, pp. 1223--1234, 2020, doi: 10.1109/tmi.2019.2946177.

\bibitem{xue2020}
Y. Xue, C. Luo, Y. Jiang, P. Yang, X. Hu, Q. Zhou, \emph{et al.}, ``Image domain multi-material decomposition using single energy CT,'' \emph{Phys. Med. Biol.}, vol.~65, no.~6, p. 065014, 2020, doi: 10.1088/1361-6560/ab7503.

\bibitem{xue2021}
Y. Xue, W. Qin, C. Luo, P. Yang, Y. Jiang, T. Tsui, \emph{et al.}, ``Multi-Material Decomposition for Single Energy CT Using Material Sparsity Constraint,'' \emph{IEEE Trans. Med. Imag.}, vol.~40, no.~5, pp. 1303--1318, 2021, doi: 10.1109/tmi.2021.3051416.

\bibitem{clark2018}
C.~T. Badea, M. Holbrook, and D.~P. Clark, ``Multi-energy CT decomposition using convolutional neural networks,'' \emph{Medical Imaging 2018: Physics of Medical Imaging}, p. 59, 2018, doi: 10.1117/12.2293728.

\bibitem{zhang2019butterfly}
W. Zhang, H. Zhang, L. Wang, X. Wang, X. Hu, A. Cai, \emph{et al.}, ``Image domain dual material decomposition for dual-energy CT using butterfly network,'' \emph{Med. Phys.}, vol.~46, no.~5, pp. 2037--2051, 2019, doi: 10.1002/mp.13489.

\bibitem{raissi2019}
M. Raissi, P. Perdikaris, and G.~E. Karniadakis, ``Physics-informed neural networks: A deep learning framework for solving forward and inverse problems involving nonlinear partial differential equations,'' \emph{J. Comput. Phys.}, vol.~378, pp. 686--707, 2019, doi: 10.1016/j.jcp.2018.10.045.

\bibitem{paterno2020}
G. Paternò, P. Cardarelli, M. Gambaccini, and A. Taibi, ``Comprehensive data set to include interference effects in Monte Carlo models of x-ray coherent scattering inside biological tissues,'' \emph{Phys. Med. Biol.}, vol.~65, no.~24, p. 245002, 2020, doi: 10.1088/1361-6560/aba7d2.

\bibitem{khodajou2026}
H. Khodajou-Chokami, H. Ding, and S. Molloi, ``Accurate iodine quantification and residual error reduction with principal component analysis multimaterial decomposition using spectral CT,'' \emph{Med. Phys.}, vol.~53, no.~4, p. e70407, 2026, doi: 10.1002/mp.70407.

\bibitem{jadick2024triplet}
G.~L. Jadick, I. Reiser, and P.~J. La Rivi\`ere, ``Sensitivity analysis of dual-energy computed tomography multi-triplet material decomposition,'' \emph{Medical Imaging 2024: Physics of Medical Imaging}, p. 76, 2024, doi: 10.1117/12.3006548.

\bibitem{phillips2025nonunique}
J.~J. Phillips, E.~Y. Sidky, I.~S. Reiser, and X. Pan, ``Dual-energy CT material decomposition in the presence of nonuniqueness,'' \emph{Phys. Med. Biol.}, vol.~70, no.~24, p. 245018, 2025, doi: 10.1088/1361-6560/ae28ae.

\bibitem{chen2025multibasis}
B. Chen, Z. Zhang, D. Xia, E.~Y. Sidky, and X. Pan, ``Multi-basis-image reconstruction from conventional data acquired in standard CT,'' \emph{Phys. Med. Biol.}, vol.~70, no.~11, p. 115005, 2025, doi: 10.1088/1361-6560/add789.

\bibitem{lalonde2017bayes}
A. Lalonde, E. B\"ar, and H. Bouchard, ``A Bayesian approach to solve proton stopping powers from noisy multi-energy CT data,'' \emph{Med. Phys.}, vol.~44, no.~10, pp. 5293--5302, 2017, doi: 10.1002/mp.12489.

\bibitem{soltani2024bayesvnc}
M. Beikali Soltani and H. Bouchard, ``Dual virtual non-contrast imaging: a Bayesian quantitative approach to determine radiotherapy quantities from contrast-enhanced DECT images,'' \emph{Phys. Med. Biol.}, vol.~69, no.~24, p. 245008, 2024, doi: 10.1088/1361-6560/ad965f.

\bibitem{jiang2025}
X. Jiang, G.~J. Gang, and J.~W. Stayman, ``Multi-Material Decomposition Using Spectral Diffusion Posterior Sampling,'' \emph{IEEE Trans. Biomed. Eng.}, vol.~72, no.~8, pp. 2447--2461, 2025, doi: 10.1109/tbme.2025.3543747.

\bibitem{bousse2024review}
A. Bousse, V.~S.~S. Kandarpa, S. Rit, A. Perelli, M. Li, G. Wang, \emph{et al.}, ``Systematic Review on Learning-Based Spectral CT,'' \emph{IEEE Trans. Radiat. Plasma Med. Sci.}, vol.~8, no.~2, pp. 113--137, 2024, doi: 10.1109/trpms.2023.3314131.

\bibitem{gong2023bdtcnn}
H. Gong, S. Leng, F. Baffour, L. Yu, J.~G. Fletcher, and C.~H. McCollough, ``Multi-energy CT material decomposition using Bayesian deep convolutional neural network with explicit penalty of uncertainty and bias,'' \emph{Medical Imaging 2023: Physics of Medical Imaging}, p. 138, 2023, doi: 10.1117/12.2654317.

\bibitem{lyu2021mdcnn}
T. Lyu, W. Zhao, Y. Zhu, Z. Wu, Y. Zhang, Y. Chen, \emph{et al.}, ``Estimating dual-energy CT imaging from single-energy CT data with material decomposition convolutional neural network,'' \emph{Med. Image Anal.}, vol.~70, p. 102001, 2021, doi: 10.1016/j.media.2021.102001.

\bibitem{peng2024fidelity}
J. Peng, C.-W. Chang, H. Xie, R.~L.~J. Qiu, J. Roper, T. Wang, \emph{et al.}, ``Image-domain material decomposition for dual-energy CT using unsupervised learning with data-fidelity loss,'' \emph{Med. Phys.}, vol.~51, no.~9, pp. 6185--6195, 2024, doi: 10.1002/mp.17255.

\bibitem{valand2026physics}
J.~H. Valand, M. Zarei, J. Rajagopal, N. Felice, J.~Y. Cao, K. Magudia, \emph{et al.}, ``Truth-based physics informed estimation of material composition in spectral CT in terms of density and effective atomic number,'' \emph{Phys. Med. Biol.}, vol.~71, no.~3, p. 035025, 2026, doi: 10.1088/1361-6560/ae4284.

\bibitem{fujiwara2022virtualct}
D. Fujiwara, T. Shimomura, W. Zhao, K.-W. Li, A. Haga, and L.-S. Geng, ``Virtual computed-tomography system for deep-learning-based material decomposition,'' \emph{Phys. Med. Biol.}, vol.~67, no.~15, p. 155008, 2022, doi: 10.1088/1361-6560/ac7bcd.

\bibitem{rajagopal2025}
J.~R. Rajagopal, S. Rapaka, F. Farhadi, E. Abadi, W.~P. Segars, T. Nowak, \emph{et al.}, ``Development of a deep learning based approach for multi-material decomposition in spectral CT: a proof of principle in silico study,'' \emph{Scientific Reports}, vol.~15, no.~1, p. 28814, 2025, doi: 10.1038/s41598-025-09739-9.

\bibitem{liu2026mmdx}
M. Liu, J. Liu, Q. Liu, and X. Bai, ``Revealing hidden material composition via physics-induced deep learning for precision clinical diagnosis,'' \emph{Patterns}, vol.~7, no.~8, p. 101620, 2026, doi: 10.1016/j.patter.2026.101620.

\bibitem{liu2024nolmbmi}
J. Liu, W. Zhao, Y. Liu, Y. Chen, and X. Bai, ``Material composition characterization from computed tomography via self-supervised learning promotes pulmonary disease diagnosis,'' \emph{Cell Reports Physical Science}, vol.~5, no.~5, p. 101940, 2024, doi: 10.1016/j.xcrp.2024.101940.

\bibitem{zhao2020psb}
W. Zhao, T. Lv, R. Lee, Y. Chen, and L. Xing, ``Obtaining dual-energy computed tomography (CT) information from a single-energy CT image for quantitative imaging analysis of living subjects by using deep learning,'' \emph{Biocomputing 2020}, pp. 139--148, 2019, doi: 10.1142/9789811215636_0013.

\bibitem{cong2020vmi}
W. Cong, Y. Xi, P. Fitzgerald, B. De Man, and G. Wang, ``Virtual Monoenergetic CT Imaging via Deep Learning,'' \emph{Patterns}, vol.~1, no.~8, p. 100128, 2020, doi: 10.1016/j.patter.2020.100128.

\bibitem{zhang2026vmi}
W. Zhang, Z. Chai, Y. Niu, Z. Zhang, L. Li, B. Sun, \emph{et al.}, ``Data-Driven Multi-keV Virtual Monoenergetic Images Generation From Single-Energy CT Guided by Image-Domain Material Decomposition,'' \emph{IEEE Trans. Comput. Imag.}, vol.~12, pp. 321--333, 2026, doi: 10.1109/tci.2026.3653309.

\bibitem{li2023enchroma}
Y. Li, X. Tie, K. Li, R. Zhang, Z. Qi, A. Budde, \emph{et al.}, ``A quality-checked and physics-constrained deep learning method to estimate material basis images from single-kV contrast-enhanced chest CT scans,'' \emph{Med. Phys.}, vol.~50, no.~6, pp. 3368--3388, 2023, doi: 10.1002/mp.16352.

\bibitem{karniadakis2021}
G.~E. Karniadakis, I.~G. Kevrekidis, L. Lu, P. Perdikaris, S. Wang, and L. Yang, ``Physics-informed machine learning,'' \emph{Nature Reviews Physics}, vol.~3, no.~6, pp. 422--440, 2021, doi: 10.1038/s42254-021-00314-5.

\bibitem{rajendran2022}
K. Rajendran, M. Petersilka, A. Henning, E.~R. Shanblatt, B. Schmidt, T.~G. Flohr, \emph{et al.}, ``First Clinical Photon-counting Detector CT System: Technical Evaluation,'' \emph{Radiology}, vol.~303, no.~1, pp. 130--138, 2022, doi: 10.1148/radiol.212579.

\bibitem{mccollough2023}
C.~H. McCollough, K. Rajendran, S. Leng, L. Yu, J.~G. Fletcher, K. Stierstorfer, \emph{et al.}, ``The technical development of photon-counting detector CT,'' \emph{Eur. Radiol.}, vol.~33, no.~8, pp. 5321--5330, 2023, doi: 10.1007/s00330-023-09545-9.

\bibitem{segars2010}
W.~P. Segars, G. Sturgeon, S. Mendonca, J. Grimes, and B.~M.~W. Tsui, ``4D XCAT phantom for multimodality imaging research,'' \emph{Med. Phys.}, vol.~37, no.~9, pp. 4902--4915, 2010, doi: 10.1118/1.3480985.

\bibitem{dahal2024xcat3}
L. Dahal, M. Ghojoghnejad, L. Vancoillie, D. Ghosh, Y. Bhandari, D. Kim, \emph{et al.}, ``XCAT 3.0: A comprehensive library of personalized digital twins derived from CT scans,'' \emph{Med. Image Anal.}, vol.~103, p. 103636, 2025, doi: 10.1016/j.media.2025.103636.

\bibitem{abadi2020vit}
E. Abadi, W.~P. Segars, B.~M.~W. Tsui, P.~E. Kinahan, N. Bottenus, A.~F. Frangi, \emph{et al.}, ``Virtual clinical trials in medical imaging: a review,'' \emph{Journal of Medical Imaging}, vol.~7, no.~04, pp. 1--40, 2020, doi: 10.1117/1.jmi.7.4.042805.

\bibitem{basissimulator}
D. Black, H. Khodajou-Chokami, and S. Molloi, ``BasisSimulator.jl: Open-source polychromatic CT simulation with a GPU-portable reconstruction stack,'' \emph{SoftwareX}, vol.~35, p. 102910, 2026, doi: 10.1016/j.softx.2026.102910.

\bibitem{geirhos2020}
R. Geirhos, J.-H. Jacobsen, C. Michaelis, R. Zemel, W. Brendel, M. Bethge, \emph{et al.}, ``Shortcut learning in deep neural networks,'' \emph{Nature Machine Intelligence}, vol.~2, no.~11, pp. 665--673, 2020, doi: 10.1038/s42256-020-00257-z.

\bibitem{guan2022domain}
H. Guan and M. Liu, ``Domain Adaptation for Medical Image Analysis: A Survey,'' \emph{IEEE Trans. Biomed. Eng.}, vol.~69, no.~3, pp. 1173--1185, 2022, doi: 10.1109/tbme.2021.3117407.
```

## Verified against arXiv on 2026-11-10

```latex
\bibitem{blackprojection}
D. Black, S. Naidu, H. Khodajou-Chokami, and S. Molloi, ``Unified projection-domain material decomposition for energy-integrating and photon-counting CT,'' 2026, arXiv:2610.30440.

\bibitem{wu2025jsover}
Q. Wu, H. Wei, J. Yu, S.~K. Zhou, and Y. Zhang, ``JSolver: Joint spectrum estimation and multi-material decomposition from single-energy CT projections,'' 2025, arXiv:2505.08123.

\bibitem{hellwege2026}
L. Hellwege, J.~C. Engster, M. Schaar, T.~M. Buzug, and M. Stille, ``Unsupervised physics-informed deep learning for dual-energy CT material decomposition,'' 2026, arXiv:2604.25356.
```
