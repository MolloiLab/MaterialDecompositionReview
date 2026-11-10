### A Pluto.jl notebook ###
# v0.20.21

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ 4d445200-0000-4000-8000-000000000001
begin
    import Pkg
    Pkg.activate(joinpath(@__DIR__, ".."))
end

# ╔═╡ 4d445200-0000-4000-8000-000000000002
using Markdown: @md_str, Markdown

# ╔═╡ 4d445200-0000-4000-8000-000000000003
using LinearAlgebra: Diagonal, diag, inv, svdvals

# ╔═╡ 4d445200-0000-4000-8000-000000000004
import PlutoUI

# ╔═╡ 4d445200-0000-4000-8000-000000000005
import BasisSimulator as BS

# ╔═╡ 4d445200-0000-4000-8000-000000000006
import CairoMakie as Mke

# ╔═╡ 4d445200-0000-4000-8000-000000000007
PlutoUI.TableOfContents()

# ╔═╡ 4d445200-0000-4000-8000-000000000008
import WasmMakie as WM

# ╔═╡ 4d445200-0000-4000-8000-000000000010
# One color per role, on warm paper
COLORS = (
    paper = Mke.RGBf(0.973, 0.969, 0.957), # #f8f7f4, every figure's background
    card = Mke.RGBf(0.941, 0.925, 0.894),  # #f0ece4, boxes in diagrams
    rule = Mke.RGBf(0.831, 0.816, 0.784),  # #d4d0c8, outlines and grid
    ink = Mke.RGBf(0.165, 0.145, 0.125),   # #2a2520, text
    muted = Mke.RGBf(0.42, 0.396, 0.376),  # #6b6560, secondary text
    night = Mke.RGBf(0.067, 0.067, 0.063), # #111110, the locator band
    night_ink = Mke.RGBf(0.94, 0.925, 0.894),
    night_muted = Mke.RGBf(0.62, 0.6, 0.57),
    violet = Mke.RGBf(0.486, 0.227, 0.929), # #7c3aed, the decomposition
    cyan = Mke.RGBf(0.031, 0.569, 0.698),   # #0891b2, measurements
    beam = Mke.RGBf(0.96, 0.62, 0.14),      # x rays
    red = Mke.RGBf(0.796, 0.235, 0.2),      # calcium, failures
    green = Mke.RGBf(0.22, 0.596, 0.149),   # iodine, passes
    blue = Mke.RGBf(0.251, 0.388, 0.847),   # water
    purple = Mke.RGBf(0.584, 0.345, 0.698), # collagen
    gold = Mke.RGBf(0.8, 0.62, 0.1),        # lipid
);

# ╔═╡ 4d445200-0000-4000-8000-000000000011
# Large, uncluttered type on warm paper for every figure
THEME = Mke.Theme(
    fontsize = 18,
    backgroundcolor = COLORS.paper,
    textcolor = COLORS.ink,
    figure_padding = (12, 24, 12, 12),
    Axis = (
        backgroundcolor = COLORS.paper,
        titlesize = 22,
        titlealign = :left,
        titlegap = 12,
        subtitlesize = 17,
        subtitlecolor = COLORS.muted,
        xlabelsize = 19,
        ylabelsize = 19,
        xticklabelsize = 16,
        yticklabelsize = 16,
        xgridcolor = (COLORS.ink, 0.07),
        ygridcolor = (COLORS.ink, 0.07),
        leftspinecolor = COLORS.rule,
        bottomspinecolor = COLORS.rule,
        xtickcolor = COLORS.rule,
        ytickcolor = COLORS.rule,
        topspinevisible = false,
        rightspinevisible = false,
        xlabelpadding = 8,
        ylabelpadding = 12,
    ),
    Legend = (
        labelsize = 17,
        framevisible = false,
        backgroundcolor = COLORS.paper,
        patchsize = (30, 14),
        rowgap = 8,
    ),
    Lines = (linewidth = 2.5,),
);

# ╔═╡ 4d445200-0000-4000-8000-000000000012
begin
    """A blank drawing area at `position`: equal scales, no axes, limits `(x0, x1, y0, y1)`."""
    function canvas(position, limits; background = COLORS.paper)
        ax = Mke.Axis(position; aspect = Mke.DataAspect(), backgroundcolor = background)
        Mke.hidedecorations!(ax)
        Mke.hidespines!(ax)
        Mke.limits!(ax, limits...)
        return ax
    end

    """The corners of a rectangle centered at `c`, `w` × `h`, its corners rounded by `r`."""
    function rounded_rect(c, w, h, r)
        x0, y0, x1, y1 = c[1] - w / 2, c[2] - h / 2, c[1] + w / 2, c[2] + h / 2
        r = min(r, w / 2, h / 2)
        arc(cx, cy, θ0) = [
            Mke.Point2f(cx + r * cos(θ), cy + r * sin(θ))
            for θ in range(θ0, θ0 + π / 2; length = 8)
        ]
        return vcat(
            arc(x1 - r, y0 + r, -π / 2),
            arc(x1 - r, y1 - r, 0.0),
            arc(x0 + r, y1 - r, π / 2),
            arc(x0 + r, y0 + r, π),
        )
    end

    """A straight arrow from `a` to `b`. `head` is the size of the arrowhead in pixels."""
    function arrow!(ax, a, b; color = COLORS.muted, linewidth = 2.5, head = 15)
        a, b = Mke.Point2f(a), Mke.Point2f(b)
        Mke.lines!(ax, [a, b]; color, linewidth)
        t = b - a
        Mke.scatter!(
            ax,
            [b];
            marker = :utriangle,
            markersize = head,
            rotation = atan(t[2], t[1]) - π / 2,
            color,
            markerspace = :pixel,
        )
        return nothing
    end

    """A box in a flow chart: centered at `c`, a bold `title` over a smaller `subtitle`."""
    function node!(ax, c, title; subtitle = "", w = 3.0, h = 1.0, accent = COLORS.violet)
        Mke.poly!(
            ax,
            rounded_rect(c, w, h, 0.14);
            color = COLORS.card,
            strokecolor = accent,
            strokewidth = 2,
        )
        strip = rounded_rect((c[1] - w / 2 + 0.06, c[2]), 0.12, h - 0.1, 0.05)
        Mke.poly!(ax, strip; color = accent)
        Mke.text!(
            ax,
            c[1] + 0.05,
            c[2] + 0.17 * h;
            text = title,
            align = (:center, :center),
            fontsize = 19,
            font = :bold,
            color = COLORS.ink,
        )
        Mke.text!(
            ax,
            c[1] + 0.05,
            c[2] - 0.22 * h;
            text = subtitle,
            align = (:center, :center),
            fontsize = 15,
            color = COLORS.muted,
        )
        return nothing
    end

    """
    A flow chart: `nodes` maps a key to `(x, y, title, subtitle, accent)`, and `edges` lists
    `from => to` pairs, drawn as arrows between the edges of the boxes. Returns the canvas.
    """
    function flow_chart!(position, nodes, edges; limits, w = 3.0, h = 1.0)
        ax = canvas(position, limits)
        function port(from, to)
            a, b = nodes[from], nodes[to]
            if abs(b[1] - a[1]) < 1.0e-6
                # one above the other
                s = sign(b[2] - a[2])
                return (a[1], a[2] + s * h / 2), (b[1], b[2] - s * h / 2)
            end
            # side by side, or leaving sideways to arrive on the facing side
            s = sign(b[1] - a[1])
            return (a[1] + s * w / 2, a[2]), (b[1] - s * w / 2, b[2])
        end
        for (from, to) in edges
            p, q = port(from, to)
            if abs(p[1] - q[1]) < 1.0e-6 || abs(p[2] - q[2]) < 1.0e-6
                arrow!(ax, p, q)
            else
                # a right-angled connector: across to the middle of the gap, along it, then in
                mx = (p[1] + q[1]) / 2
                Mke.lines!(
                    ax,
                    Mke.Point2f[p, (mx, p[2]), (mx, q[2])];
                    color = COLORS.muted,
                    linewidth = 2.5,
                )
                arrow!(ax, (mx, q[2]), q)
            end
        end
        for (_, n) in nodes
            node!(ax, (n[1], n[2]), n[3]; subtitle = n[4], accent = n[5], w, h)
        end
        return ax
    end

    """
    The dark band that opens the notebook: one drawing area per entry of `titles`, each with a
    bold title and a smaller subtitle beneath. Returns the figure and its drawing areas.
    """
    function locator_band(titles, subtitles; limits, size = (1500, 560))
        fig = Mke.Figure(;
            size,
            backgroundcolor = COLORS.night,
            figure_padding = (10, 10, 18, 10),
        )
        axes = [
            canvas(fig[1, i], limits[i]; background = COLORS.night)
            for i in eachindex(titles)
        ]
        for i in eachindex(titles)
            Mke.Label(
                fig[2, i],
                titles[i];
                fontsize = 25,
                font = :bold,
                color = COLORS.night_ink,
                tellwidth = false,
            )
            Mke.Label(
                fig[3, i],
                subtitles[i];
                fontsize = 17,
                color = COLORS.night_muted,
                tellwidth = false,
            )
        end
        Mke.rowgap!(fig.layout, 1, 8)
        Mke.rowgap!(fig.layout, 2, 2)
        return fig, axes
    end
end;

# ╔═╡ 4d445200-0000-4000-8000-000000000013
begin
    """A voxel drawn as slabs of its materials, one color each, with their names beside it."""
    function voxel!(ax; dark = false)
        ink = dark ? COLORS.night_ink : COLORS.ink
        parts = [
            ("Lipid", COLORS.gold, 0.2),
            ("Water", COLORS.blue, 0.42),
            ("Collagen", COLORS.purple, 0.16),
            ("Calcium", COLORS.red, 0.1),
            ("Iodine", COLORS.green, 0.12),
        ]
        x = -5.4
        for (i, (name, color, share)) in enumerate(parts)
            w = 6.4 * share
            Mke.poly!(
                ax,
                Mke.Rect2f(x, -3.2, w, 6.4);
                color,
                strokecolor = ink,
                strokewidth = 1,
            )
            x += w
            # the key: a swatch and the name
            y = 2.6 - 1.3 * (i - 1)
            Mke.poly!(
                ax,
                Mke.Rect2f(1.9, y - 0.3, 0.6, 0.6);
                color,
                strokecolor = ink,
                strokewidth = 1,
            )
            Mke.text!(
                ax,
                2.8,
                y;
                text = name,
                align = (:left, :center),
                fontsize = 16,
                color = ink,
            )
        end
        Mke.poly!(
            ax,
            Mke.Rect2f(-5.4, -3.2, 6.4, 6.4);
            color = :transparent,
            strokecolor = ink,
            strokewidth = 2.5,
        )
        return nothing
    end

    """A ray from the source through the object to one detector element, with its `K` counts."""
    function ray!(ax; K = 2, dark = false)
        ink = dark ? COLORS.night_ink : COLORS.ink
        Mke.lines!(ax, Mke.Point2f[(-6.5, 0), (6.5, 0)]; color = COLORS.beam, linewidth = 4)
        Mke.scatter!(ax, Mke.Point2f[(-6.5, 0)]; color = COLORS.beam, markersize = 24)
        θ = range(0, 2π; length = 90)
        Mke.poly!(
            ax,
            Mke.Point2f.(3.0 .* cos.(θ), 2.2 .* sin.(θ));
            color = (COLORS.blue, 0.35),
            strokecolor = ink,
            strokewidth = 2,
        )
        Mke.poly!(
            ax,
            Mke.Rect2f(6.5, -1.6, 0.8, 3.2);
            color = COLORS.cyan,
            strokecolor = ink,
            strokewidth = 1.5,
        )
        for k in 1:K
            y = 1.6 - 3.2 * (k - 0.5) / K
            Mke.text!(
                ax,
                7.7,
                y;
                text = "Count $(k)",
                align = (:left, :center),
                fontsize = 16,
                color = ink,
            )
        end
        Mke.text!(
            ax,
            -6.5,
            -1.2;
            text = "Source",
            align = (:center, :center),
            fontsize = 16,
            color = ink,
        )
        Mke.text!(
            ax,
            0.0,
            -3.2;
            text = "Object",
            align = (:center, :center),
            fontsize = 16,
            color = ink,
        )
        return nothing
    end

    """The counting ladder: how many amounts a voxel's measurements determine."""
    function ladder!(ax; dark = false)
        ink = dark ? COLORS.night_ink : COLORS.ink
        rungs = [
            ("One Measurement", 1),
            ("Two Measurements", 2),
            ("Two, and Volume Conserved", 3),
        ]
        for (i, (label, amounts)) in enumerate(rungs)
            y = 3.4 - 3.0 * (i - 1)
            Mke.text!(
                ax,
                -7.2,
                y + 1.0;
                text = label,
                align = (:left, :center),
                fontsize = 16,
                color = ink,
            )
            for n in 1:3
                filled = n <= amounts
                Mke.poly!(
                    ax,
                    Mke.Rect2f(-7.2 + 1.7 * (n - 1), y - 0.75, 1.3, 1.3);
                    color = filled ? COLORS.violet : :transparent,
                    strokecolor = ink,
                    strokewidth = 1.5,
                )
            end
            Mke.text!(
                ax,
                -1.6,
                y - 0.1;
                text = amounts == 1 ? "1 Amount" : "$(amounts) Amounts",
                align = (:left, :center),
                fontsize = 16,
                color = ink,
            )
        end
        return nothing
    end
end;

# ╔═╡ 4d445200-0000-4000-8000-000000000020
# The energy samples of the notebook (keV): the grid of the simulator's 140 kVp spectrum
ENERGIES = let
    energies, _ = BS.load_spectrum_unfiltered(140)
    energies[energies .>= 20.0]
end;

# ╔═╡ 4d445200-0000-4000-8000-000000000021
"""The mass attenuation coefficient of `material` at every energy sample (cm²/g)."""
mass_attenuation(material) = [BS.compute_mass_μ_at_energy(material, E) for E in ENERGIES]

# ╔═╡ 4d445200-0000-4000-8000-000000000022
# The basis materials of the notebook, each as its mass attenuation curve
BASIS = (
    water = mass_attenuation(BS.XA.Materials.water),
    lipid = mass_attenuation(BS.XA.Materials.basis_lipid),
    collagen = mass_attenuation(BS.XA.Materials.basis_collagen),
    hydroxyapatite = mass_attenuation(BS.XA.Materials.hydroxyapatite),
    iodine = mass_attenuation(BS.XA.Elements.Iodine),
    gadolinium = mass_attenuation(BS.XA.Elements.Gadolinium),
);

# ╔═╡ 4d445200-0000-4000-8000-000000000030
"""
How much of the attenuation curves in the columns of `F` (energies × materials) is left after the
best representation by `r` energy functions, as a fraction of the whole (0 to 1). Each curve is
first scaled to unit length, so a dense material counts no more than a light one.
"""
function basis_residual(F, r)
    σ = svdvals(F ./ sqrt.(sum(abs2, F; dims = 1)))
    return sqrt(sum(abs2, σ[(r + 1):end]; init = 0.0) / sum(abs2, σ))
end

# ╔═╡ 4d445200-0000-4000-8000-000000000031
# Tissues and basis materials without a K-edge between 20 and 140 keV
TISSUES = [
    ("Water", BS.XA.Materials.water),
    ("Adipose", BS.XA.Materials.adipose),
    ("Muscle", BS.XA.Materials.muscle),
    ("Lung", BS.XA.Materials.lung),
    ("Brain", BS.XA.Materials.brain),
    ("Blood", BS.XA.Materials.blood),
    ("Liver", BS.XA.Materials.liver),
    ("Lipid", BS.XA.Materials.basis_lipid),
    ("Collagen", BS.XA.Materials.basis_collagen),
    ("Hydroxyapatite", BS.XA.Materials.hydroxyapatite),
];

# ╔═╡ 4d445200-0000-4000-8000-000000000032
# The curves of the tissues alone, and with the two contrast elements whose K-edges lie in range
F_TISSUES = reduce(hcat, [mass_attenuation(material) for (_, material) in TISSUES]);

# ╔═╡ 4d445200-0000-4000-8000-000000000033
F_WITH_EDGES = hcat(F_TISSUES, BASIS.iodine, BASIS.gadolinium);

# ╔═╡ 4d445200-0000-4000-8000-000000000034
# The residual (%) after one to four functions, for each set of curves
RESIDUALS = (
    tissues = [100 * basis_residual(F_TISSUES, r) for r in 1:4],
    with_edges = [100 * basis_residual(F_WITH_EDGES, r) for r in 1:4],
)

# ╔═╡ 4d445200-0000-4000-8000-000000000040
"""
The spectrum of the tube at `kVp` behind `filters` (material, thickness in mm), on the energy
samples of the notebook, in photons per sample on the scale of the simulator's spectrum tables.
"""
function beam(kVp; filters = [("Al", 4.5)])
    energies, flux = BS.load_spectrum_unfiltered(kVp)
    _, filtered = BS.filter_spectrum(
        energies,
        flux;
        filters = Tuple{String, Float64}[filters...],
    )
    lookup = Dict(zip(energies, filtered))
    return [get(lookup, E, 0.0) for E in ENERGIES]
end

# ╔═╡ 4d445200-0000-4000-8000-000000000041
# Photons that reach one detector element in one measurement, without the object and without tin
PHOTONS = 1.0e6;

# ╔═╡ 4d445200-0000-4000-8000-000000000042
# The spectral response of each beam with the ideal detector, scaled to PHOTONS in total
S_LOW = PHOTONS .* beam(80) ./ sum(beam(80));

# ╔═╡ 4d445200-0000-4000-8000-000000000043
S_HIGH = PHOTONS .* beam(140) ./ sum(beam(140));

# ╔═╡ 4d445200-0000-4000-8000-000000000044
S_SINGLE = PHOTONS .* beam(120) ./ sum(beam(120));

# ╔═╡ 4d445200-0000-4000-8000-000000000045
# The linear attenuation of tin at every energy sample (per mm), from the simulator's own filter
TIN_MU = let
    bare = beam(140)
    thin = beam(140; filters = [("Al", 4.5), ("Sn", 0.1)])
    [b > 0 ? -log(t / b) / 0.1 : 0.0 for (t, b) in zip(thin, bare)]
end;

# ╔═╡ 4d445200-0000-4000-8000-000000000046
"""
The `2 × N_E` spectral responses of a dual-energy acquisition: the 80 kVp beam, and the 140 kVp
beam behind `tin_mm` of tin at the same tube output.
"""
dual_energy(tin_mm) = permutedims(hcat(S_LOW, S_HIGH .* exp.(-TIN_MU .* tin_mm)))

# ╔═╡ 4d445200-0000-4000-8000-000000000047
# The thresholds (keV) of four ideal energy windows on the 140 kVp beam
THRESHOLDS = [20.0, 35.0, 55.0, 70.0];

# ╔═╡ 4d445200-0000-4000-8000-000000000048
# The `4 × N_E` spectral responses of the four windows: each photon counted in the window of its energy
S_WINDOWS = let
    upper = vcat(THRESHOLDS[2:end], Inf)
    windows = [
        S_HIGH .* (THRESHOLDS[k] .<= ENERGIES .< upper[k])
        for k in eachindex(THRESHOLDS)
    ]
    permutedims(reduce(hcat, windows))
end;

# ╔═╡ 4d445200-0000-4000-8000-000000000050
"""
The expected value of each of the `K` measurements of a ray with the basis line integrals `a`.
`S` is `K × N_E` (spectral responses) and `F` is `N_E × M` (mass attenuation coefficients).
"""
expected_counts(S, F, a) = S * exp.(-(F * a))

# ╔═╡ 4d445200-0000-4000-8000-000000000051
"""The `K × M` derivative of [`expected_counts`](@ref) with respect to the line integrals."""
count_jacobian(S, F, a) = -(S * (exp.(-(F * a)) .* F))

# ╔═╡ 4d445200-0000-4000-8000-000000000052
"""
The `M × M` Fisher information of the line integrals `a` when the `K` measurements are independent
Poisson counts.
"""
function fisher_information(S, F, a)
    J = count_jacobian(S, F, a)
    return J' * (J ./ expected_counts(S, F, a))
end

# ╔═╡ 4d445200-0000-4000-8000-000000000053
"""
The Cramér–Rao lower bound of each line integral as a standard deviation (g/cm²). It needs `K ≥ M`
measurements whose sensitivities to the `M` materials are linearly independent.
"""
crlb(S, F, a) = sqrt.(diag(inv(fisher_information(S, F, a))))

# ╔═╡ 4d445200-0000-4000-8000-000000000054
"""
The `K × M` effective mass attenuation coefficients at the operating point `a`: row `k` holds the
coefficients of the materials averaged over the spectrum that measurement `k` detects behind the
object. Image-domain decomposition inverts this linear model.
"""
effective_attenuation(S, F, a) = -count_jacobian(S, F, a) ./ expected_counts(S, F, a)

# ╔═╡ 4d445200-0000-4000-8000-000000000055
# Water and iodine as the two basis materials (columns), and the ray the bounds are evaluated on:
# 20 g/cm² of water (20 cm) and 0.02 g/cm² of iodine (2 cm of a 10 mg/mL solution)
F_WATER_IODINE = hcat(BASIS.water, BASIS.iodine);

# ╔═╡ 4d445200-0000-4000-8000-000000000056
OPERATING_POINT = [20.0, 0.02];

# ╔═╡ 4d445200-0000-4000-8000-000000000060
# Tin thicknesses tried on the 140 kVp beam (mm)
TIN_SWEEP = collect(0.0:0.1:1.0);

# ╔═╡ 4d445200-0000-4000-8000-000000000061
# The bounds of the water and iodine line integrals (g/cm²) at each thickness
BOUND_SWEEP = [crlb(dual_energy(t), F_WATER_IODINE, OPERATING_POINT) for t in TIN_SWEEP];

# ╔═╡ 4d445200-0000-4000-8000-000000000062
# The thickness with the lowest iodine bound among those tried
BEST_TIN = TIN_SWEEP[argmin(last.(BOUND_SWEEP))]

# ╔═╡ 4d445200-0000-4000-8000-000000000063
"""The correlation between the errors of the water and iodine estimates at the bound."""
function error_correlation(S)
    C = inv(fisher_information(S, F_WATER_IODINE, OPERATING_POINT))
    return C[1, 2] / sqrt(C[1, 1] * C[2, 2])
end

# ╔═╡ 4d445200-0000-4000-8000-000000000064
@bind tin_tenths PlutoUI.Slider(0:10; default = 4)

# ╔═╡ 4d445200-0000-4000-8000-000000000066
# The readout at every position of the slider, computed once when the notebook is rendered. A tuple
# of tuples of plain numbers is carried into the WebAssembly island as a constant.
TIN_READOUTS = Tuple(
    let S = dual_energy(t), bound = crlb(S, F_WATER_IODINE, OPERATING_POINT)
        (
            t,
            round(1000 * bound[2]; digits = 2),
            round(bound[1]; digits = 3),
            round(error_correlation(S); digits = 3),
            round(Int, sum(S[2, :])),
        )
    end
    for t in TIN_SWEEP
);

# ╔═╡ 4d445200-0000-4000-8000-000000000067
# The sweep as tuples of plain numbers, for the figure the slider drives: thickness (mm) and the
# bound of the iodine line integral (mg/cm²)
begin
    TIN_MM = Tuple(TIN_SWEEP)
    IODINE_BOUND_MG = Tuple(1000 .* last.(BOUND_SWEEP))
end;

# ╔═╡ 4d445200-0000-4000-8000-000000000068
# what the readout below shows, as plain numbers
tin_readout = TIN_READOUTS[tin_tenths + 1];

# ╔═╡ 4d445200-0000-4000-8000-000000000070
# The acquisitions compared: their names and spectral responses
ACQUISITIONS = [
    ("Single Energy, 120 kVp", permutedims(S_SINGLE)),
    ("Dual Energy, 80 and 140 kVp With Tin", dual_energy(BEST_TIN)),
    ("Four Energy Windows, 140 kVp", S_WINDOWS),
];

# ╔═╡ 4d445200-0000-4000-8000-000000000071
# The sets of materials a voxel is allowed to hold
MATERIAL_SETS = [
    ("Water, Iodine", (:water, :iodine)),
    ("Water, Hydroxyapatite, Iodine", (:water, :hydroxyapatite, :iodine)),
    (
        "Lipid, Water, Collagen, Hydroxyapatite, Iodine",
        (:lipid, :water, :collagen, :hydroxyapatite, :iodine),
    ),
];

# ╔═╡ 4d445200-0000-4000-8000-000000000072
# A singular value below this share of the largest is counted as not determined (chosen)
TOLERANCE = 0.01;

# ╔═╡ 4d445200-0000-4000-8000-000000000073
"""
The singular values of the effective attenuation of `materials` under the spectral responses `S`,
each divided by the largest, for a ray through 20 g/cm² of water. Each material's column is scaled
to unit length first, so the result does not depend on the units of its amount.
"""
function singular_ratios(S, materials)
    F = reduce(hcat, [BASIS[m] for m in materials])
    a = [m === :water ? OPERATING_POINT[1] : 0.0 for m in materials]
    A = effective_attenuation(S, F, a)
    σ = svdvals(A ./ sqrt.(sum(abs2, A; dims = 1)))
    return σ ./ σ[1]
end

# ╔═╡ 4d445200-0000-4000-8000-000000000074
# Every acquisition with every set of materials: the ratios and how many pass the limit
LADDER = [
    (
        acquisition = acquisition,
        materials = set,
        n_materials = length(materials),
        ratios = singular_ratios(S, materials),
    )
    for (acquisition, S) in ACQUISITIONS, (set, materials) in MATERIAL_SETS
];

# ╔═╡ 4d445200-0000-4000-8000-000000000075
"""How many amounts an entry of `LADDER` determines: its singular-value ratios above the limit."""
determined(entry) = count(>(TOLERANCE), entry.ratios)

# ╔═╡ 4d445200-0000-4000-8000-000000000079
"""`x` to two significant digits as text, without a trailing `.0`."""
function two_digits(x)
    r = round(x; sigdigits = 2)
    return r == round(r) ? string(round(Int, r)) : string(r)
end

# ╔═╡ 4d445200-0000-4000-8000-000000000080
# key, value, unit, note
RESULTS = [
    (
        "mm-n-tissues",
        string(length(TISSUES)),
        "",
        "tissues and basis materials without a K-edge in range",
    ),
    ("mm-residual-tissues-1", two_digits(RESIDUALS.tissues[1]), "%", "one energy function"),
    (
        "mm-residual-tissues-2",
        two_digits(RESIDUALS.tissues[2]),
        "%",
        "two energy functions",
    ),
    (
        "mm-residual-edges-2",
        two_digits(RESIDUALS.with_edges[2]),
        "%",
        "two functions with iodine and gadolinium",
    ),
    (
        "mm-residual-edges-3",
        two_digits(RESIDUALS.with_edges[3]),
        "%",
        "three functions with iodine and gadolinium",
    ),
    (
        "mm-residual-edges-4",
        two_digits(RESIDUALS.with_edges[4]),
        "%",
        "four functions with iodine and gadolinium",
    ),
    (
        "mm-tin-best",
        string(BEST_TIN),
        "mm",
        "tin thickness with the lowest iodine bound among 0 to 1 mm",
    ),
    (
        "mm-bound-iodine-no-tin",
        string(round(1000 * BOUND_SWEEP[1][2]; digits = 2)),
        "mg/cm2",
        "iodine bound without tin",
    ),
    (
        "mm-bound-iodine-best",
        string(round(1000 * minimum(last, BOUND_SWEEP); digits = 2)),
        "mg/cm2",
        "lowest iodine bound",
    ),
    (
        "mm-correlation-best",
        string(round(error_correlation(dual_energy(BEST_TIN)); digits = 3)),
        "",
        "correlation of water and iodine errors at the lowest bound",
    ),
    [
        (
            "mm-determined-$(("se", "de", "pc")[i])-$(LADDER[i, j].n_materials)",
            string(determined(LADDER[i, j])),
            "",
            "amounts determined at the 1% limit",
        )
        for i in eachindex(ACQUISITIONS)
        for j in eachindex(MATERIAL_SETS)
    ]...,
];

# ╔═╡ 4d445200-0000-4000-8000-000000000081
let
    open(joinpath(@__DIR__, "..", "results", "measurement_model.csv"), "w") do io
        println(io, "key,value,unit,note")
        for row in RESULTS
            println(io, join(row, ","))
        end
    end
    Markdown.parse("Wrote $(length(RESULTS)) values to `results/measurement_model.csv`.")
end

# ╔═╡ 4d445200-0000-4000-8000-000000000085
# The census as written by scripts/literature_census.py: one row per year, then the totals
CENSUS = let
    lines = readlines(joinpath(@__DIR__, "..", "results", "literature_census.csv"))
    rows = [split(line, ",") for line in lines if !isempty(line) && isdigit(first(line))]
    totals = split(only(filter(startswith("#total,"), lines)), ",")[2:end]
    column(i) = [parse(Int, row[i]) for row in rows]
    (
        year = column(1),
        all = column(2),
        learned = column(4),
        review = column(5),
        total_all = parse(Int, totals[1]),
        total_learned = parse(Int, totals[3]),
        total_review = parse(Int, totals[4]),
    )
end;

# ╔═╡ 4d445200-0000-4000-8000-000000000090
# name, measured value, pass
CHECKS = let
    S, F, a = S_WINDOWS, F_WATER_IODINE, OPERATING_POINT
    # the Jacobian against central differences
    h = (1.0e-4, 1.0e-7)
    numeric = hcat(
        (expected_counts(S, F, a .+ [h[1], 0]) .- expected_counts(S, F, a .- [h[1], 0])) ./
            (2 * h[1]),
        (expected_counts(S, F, a .+ [0, h[2]]) .- expected_counts(S, F, a .- [0, h[2]])) ./
            (2 * h[2]),
    )
    J = count_jacobian(S, F, a)
    jacobian_error = maximum(abs.(J .- numeric) ./ abs.(J))
    # two monoenergetic measurements: the model is log-linear and the bound has a closed form
    A = [0.25 4.0; 0.18 0.9]
    N = [3.0e5 0.0; 0.0 2.0e5]
    exact = sqrt.(diag(inv(A) * Diagonal(1 ./ expected_counts(N, A, a)) * inv(A)'))
    closed_form_error = maximum(abs.(crlb(N, A, a) .- exact) ./ exact)
    # summing the four windows into two cannot lower the bound
    merged = vcat(sum(S[1:2, :]; dims = 1), sum(S[3:4, :]; dims = 1))
    merging_ratio = minimum(crlb(merged, F, a) ./ crlb(S, F, a))
    # without an object every measurement counts its whole spectral response
    air_error = maximum(abs, expected_counts(S, F, [0.0, 0.0]) .- vec(sum(S; dims = 2)))
    # the four windows together hold the 140 kVp beam
    window_error = abs(sum(S) - sum(S_HIGH)) / sum(S_HIGH)
    # as many functions as curves leave no residual
    full_residual = basis_residual(F_TISSUES, size(F_TISSUES, 2))
    [
        (
            "Jacobian against central differences, largest relative error",
            jacobian_error,
            jacobian_error < 1.0e-6,
        ),
        (
            "Bound of two monoenergetic measurements against its closed form, relative error",
            closed_form_error,
            closed_form_error < 1.0e-10,
        ),
        (
            "Bound after summing four windows into two, smallest ratio to the four-window bound",
            merging_ratio,
            merging_ratio >= 1,
        ),
        (
            "Counts without an object against the spectral response, largest difference",
            air_error,
            air_error < 1.0e-6,
        ),
        (
            "The four windows against the whole 140 kVp beam, relative difference",
            window_error,
            window_error < 1.0e-12,
        ),
        (
            "Residual after as many functions as curves",
            full_residual,
            full_residual < 1.0e-10,
        ),
        (
            "Residual of the tissues falls with every added function",
            RESIDUALS.tissues[4] / RESIDUALS.tissues[1],
            issorted(RESIDUALS.tissues; rev = true),
        ),
    ]
end;

# ╔═╡ 4d445200-0000-4000-8000-000000000100
md"""
# Material Decomposition in CT

**One measurement model, three questions, and every class of material decomposition, each to be run
on the same simulated scans.**

Material decomposition turns the energy dependence of CT measurements into amounts of materials.
This notebook is the walk-through of a review of its methods and the source of every method,
figure, and number in that review. This first part builds the measurement model that every method
inverts, with the spectra and cross sections of `BasisSimulator.jl`, and counts how many material
amounts a set of measurements determines. The methods follow in the parts listed at the end.
"""

# ╔═╡ 4d445200-0000-4000-8000-000000000101
md"""
## The Chain at a Glance

Every method in the review inverts one model. The materials of the object attenuate a
polychromatic beam, the scanner records `K` spectral measurements of each ray, and a decomposition
turns them into material maps. The methods differ in three respects: where they invert the model,
what closes the system when a voxel can hold more materials than the measurements determine, and
how they report the answer.
"""

# ╔═╡ 4d445200-0000-4000-8000-000000000102
md"""
## Notebook Setup
"""

# ╔═╡ 4d445200-0000-4000-8000-000000000103
md"""
## Figure Style

The palette, the theme, and the drawing helpers follow the example notebooks of
`BasisSimulator.jl`.
"""

# ╔═╡ 4d445200-0000-4000-8000-000000000110
md"""
## 1. The Materials

A voxel is described by the volume fractions of a few basis materials. Each material enters the
measurement only through its mass attenuation coefficient, which depends on the photon energy.
The coefficients below are computed from the NIST XCOM cross sections that `BasisSimulator.jl`
uses, on the energy grid of its 140 kVp spectrum from 20 keV upward.
"""

# ╔═╡ 4d445200-0000-4000-8000-000000000111
md"""
## 2. Two Functions, Until a K-Edge

Alvarez and Macovski (1976) showed that the attenuation of a material without a K-edge in the
diagnostic range can be approximated by two functions of energy, one for photoelectric absorption
and one for Compton scattering. Two basis materials span the same two functions. This section
measures how much of each set of curves two functions leave unexplained. Each curve is scaled to
unit length, and the best `r` functions are the leading singular vectors of the set
(Eckart and Young), so the residual is the share of the curves outside them.
"""

# ╔═╡ 4d445200-0000-4000-8000-000000000112
md"""
## 3. The Measurement

A scanner does not measure attenuation at one energy. Measurement `k` of a ray has the expected
value

```math
\lambda_k=\sum_{e} S_{k}(E_e)\,\exp\Big[-\sum_{m} f_m(E_e)\,A_m\Big],
```

where `A_m` is the line integral of basis material `m` along the ray (g/cm²), `f_m(E)` its mass
attenuation coefficient, and `S_k(E)` the spectral response of the measurement, the expected count
at each energy without the object. This is the model of Alvarez and Macovski (1976) with basis
materials (Lehmann et al. 1981), in the notation of Black et al. (2026, arXiv:2610.30440), written
for `M` materials. In the code, `S` holds the responses (measurements × energies), `F` the
coefficients (energies × materials), and `a` the line integrals. The acquisition enters only
through `S`. This part uses the tube spectra of `BasisSimulator.jl` behind 4.5 mm of aluminum and an ideal
detector that counts every photon. The detector responses of real scanners enter in a later part.
"""

# ╔═╡ 4d445200-0000-4000-8000-000000000113
md"""
## 4. What Two Measurements Determine

Two measurements determine two line integrals, and the noise of the estimate depends on how
differently the two beams see the two materials. For independent Poisson counts, the Fisher
information gives the Cramér–Rao lower bound, the smallest standard deviation any unbiased
estimator can reach. A tin filter on the 140 kVp beam separates the two spectra and removes
photons at the same time. The slider sets its thickness at a fixed tube output, and the
readout and the marked point follow it in the browser.
"""

# ╔═╡ 4d445200-0000-4000-8000-000000000114
md"""
## 5. The Counting Ladder

How many material amounts do `K` measurements determine? Around an operating point the
measurements respond to small changes of the amounts through the effective attenuation, a `K × M`
matrix. Its singular values show how strongly the measurements respond to each independent
combination of the materials. A combination whose singular value is far below the largest is
determined only with a correspondingly amplified noise. The count below uses a ratio of 1% as the
limit, a chosen value, and the figure shows every ratio.
"""

# ╔═╡ 4d445200-0000-4000-8000-000000000115
md"""
## 7. Results for the Paper

Every number the paper states comes from this notebook. The cell below writes them to
`results/measurement_model.csv`, and `paper/make_values.py` turns that file into the macros the
manuscript prints.
"""

# ╔═╡ 4d445200-0000-4000-8000-000000000116
md"""
## 8. Verification

The functions above are checked against results that are known exactly.
"""

# ╔═╡ 4d445200-0000-4000-8000-000000000117
md"""
## What Comes Next

The parts that follow add one class of methods each, with one representative method written out
in full and run on the same simulated scans of `BasisSimulator.jl`.

| Part | Class | Question it answers |
|:---|:---|:---|
| Acquisition | single energy, kVp switching, dual source, photon counting | how the `K` measurements are made |
| Projection domain | calibration and likelihood per ray | inversion before reconstruction |
| Image domain | linear inversion per voxel | inversion after reconstruction |
| One-step | penalized likelihood on the raw data | inversion and reconstruction together |
| Three materials | conservation of volume or mass | one more material than measurements |
| Multi-material | a library of triplets | more materials in the image than in a voxel |
| Single energy | a library of pairs | one measurement |
| Probabilistic | probabilities of mixtures | the ambiguity reported, not resolved |
| Learned | supervised and physics-informed networks | information from training data |
| Benchmark | every representative method | the same scans, the same metrics |
"""

# ╔═╡ 4d445200-0000-4000-8000-000000000118
md"""
## 6. The Literature in Numbers

How large is the field this review covers? `scripts/literature_census.py` counts the PubMed records
of each year that name material or basis decomposition with CT in their title or abstract, those
that also name a learning method, and those listed as reviews. The counts leave out conference
papers and journals that PubMed does not index.
"""

# ╔═╡ 4d445200-0000-4000-8000-000000000700
let
    Mke.set_theme!(THEME)
    fig, axes = locator_band(
        ["The Object", "The Measurement", "The Count"],
        [
            "A Voxel Holds a Mixture of Materials",
            "Each Ray Has K Spectral Measurements",
            "K Measurements Determine a Limited Number of Amounts",
        ];
        limits = [(-7, 7, -5, 5), (-8, 10, -6, 6), (-8, 8, -5.5, 5.5)],
    )
    voxel!(axes[1]; dark = true)
    ray!(axes[2]; K = 2, dark = true)
    ladder!(axes[3]; dark = true)
    fig
end

# ╔═╡ 4d445200-0000-4000-8000-000000000710
let
    Mke.set_theme!(THEME)
    fig = Mke.Figure(size = (1500, 420))
    nodes = Dict(
        :materials => (0.0, 2.4, "Materials", "Attenuation of a Mixture", COLORS.blue),
        :beam => (4.6, 2.4, "Spectral Responses", "One per Measurement", COLORS.beam),
        :counts => (9.2, 2.4, "K Measurements", "For Every Ray", COLORS.cyan),
        :decomposition => (13.8, 2.4, "Decomposition", "Inverts the Model", COLORS.violet),
        :maps => (18.4, 2.4, "Material Maps", "Amounts in Every Voxel", COLORS.green),
        :where => (9.2, 0.0, "Where", "Projection, Image, One-Step", COLORS.violet),
        :closure => (13.8, 0.0, "Closure", "Conservation, Library, Prior", COLORS.violet),
        :report => (18.4, 0.0, "Report", "Estimate or Probability", COLORS.violet),
    )
    edges = [
        :materials => :beam,
        :beam => :counts,
        :counts => :decomposition,
        :decomposition => :maps,
    ]
    w, h = 3.8, 1.15
    ax = flow_chart!(fig[1, 1], nodes, edges; limits = (-2.2, 20.6, -0.9, 3.3), w, h)
    # the three questions join in one line that enters the decomposition from below
    bus = 1.2
    for key in (:where, :closure, :report)
        x = nodes[key][1]
        Mke.lines!(
            ax,
            Mke.Point2f[(x, h / 2), (x, bus)];
            color = COLORS.muted,
            linewidth = 2.5,
        )
    end
    Mke.lines!(
        ax,
        Mke.Point2f[(nodes[:where][1], bus), (nodes[:report][1], bus)];
        color = COLORS.muted,
        linewidth = 2.5,
    )
    arrow!(ax, (nodes[:decomposition][1], bus), (nodes[:decomposition][1], 2.4 - h / 2))
    Mke.save(joinpath(@__DIR__, "..", "paper", "figures", "fig_framework.pdf"), fig)
    fig
end

# ╔═╡ 4d445200-0000-4000-8000-000000000720
let
    Mke.set_theme!(THEME)
    fig = Mke.Figure(size = (1400, 900))
    # what the curves describe: a voxel as a mixture
    voxel!(canvas(fig[1, 1], (-7, 7, -3.8, 3.8)))
    ax = Mke.Axis(
        fig[2, 1];
        title = "Mass Attenuation of the Basis Materials",
        subtitle = "NIST XCOM Cross Sections, 20 to 140 keV",
        xlabel = "Photon Energy (keV)",
        ylabel = "Mass Attenuation Coefficient (cm²/g)",
        yscale = log10,
    )
    curves = [
        ("Lipid", BASIS.lipid, COLORS.gold),
        ("Water", BASIS.water, COLORS.blue),
        ("Collagen", BASIS.collagen, COLORS.purple),
        ("Hydroxyapatite", BASIS.hydroxyapatite, COLORS.red),
        ("Iodine", BASIS.iodine, COLORS.green),
        ("Gadolinium", BASIS.gadolinium, COLORS.cyan),
    ]
    for (name, curve, color) in curves
        Mke.lines!(ax, ENERGIES, curve; color, label = name)
    end
    Mke.axislegend(ax; position = :rt, nbanks = 2)
    Mke.rowsize!(fig.layout, 1, Mke.Relative(0.3))
    fig
end

# ╔═╡ 4d445200-0000-4000-8000-000000000730
let
    Mke.set_theme!(THEME)
    fig = Mke.Figure(size = (1100, 620))
    ax = Mke.Axis(
        fig[1, 1];
        title = "What Two Energy Functions Leave Unexplained",
        subtitle = "Residual of the Attenuation Curves, 20 to 140 keV",
        xlabel = "Number of Energy Functions",
        ylabel = "Residual (%)",
        yscale = log10,
        xticks = 1:4,
    )
    Mke.scatterlines!(
        ax,
        1:4,
        RESIDUALS.tissues;
        color = COLORS.blue,
        markersize = 14,
        label = "$(length(TISSUES)) Tissues and Basis Materials",
    )
    Mke.scatterlines!(
        ax,
        1:4,
        RESIDUALS.with_edges;
        color = COLORS.green,
        markersize = 14,
        label = "With Iodine and Gadolinium",
    )
    Mke.axislegend(ax; position = :rt)
    fig
end

# ╔═╡ 4d445200-0000-4000-8000-000000000731
Markdown.parse(
    """
| Energy functions | $(length(TISSUES)) tissues and basis materials | With iodine and gadolinium |
|:---|---:|---:|
$(join(["| $(r) | $(two_digits(RESIDUALS.tissues[r])) % | $(two_digits(RESIDUALS.with_edges[r])) % |" for r in 1:4], "\n"))

The first column is the residual of materials without a K-edge in range. The second adds iodine,
whose K-edge lies at 33.2 keV, and gadolinium, whose K-edge lies at 50.2 keV. The number of
functions a set of materials needs is called `D` below.
""",
)

# ╔═╡ 4d445200-0000-4000-8000-000000000740
let
    Mke.set_theme!(THEME)
    fig = Mke.Figure(size = (1400, 900))
    # one ray and its two counts
    ray!(canvas(fig[1, 1:2], (-8, 11, -4, 3)); K = 2)
    transmission = exp.(-(F_WATER_IODINE * OPERATING_POINT))
    ax1 = Mke.Axis(
        fig[2, 1];
        title = "Spectral Responses Without the Object",
        subtitle = "80 and 140 kVp Behind 4.5 mm of Aluminum",
        xlabel = "Photon Energy (keV)",
        ylabel = "Expected Count per Energy Sample",
    )
    Mke.lines!(ax1, ENERGIES, S_LOW; color = COLORS.cyan, label = "80 kVp")
    Mke.lines!(ax1, ENERGIES, S_HIGH; color = COLORS.violet, label = "140 kVp")
    Mke.axislegend(ax1; position = :rt)
    ax2 = Mke.Axis(
        fig[2, 2];
        title = "What Reaches the Detector",
        subtitle = "Behind 20 cm of Water and 0.02 g/cm² of Iodine",
        xlabel = "Photon Energy (keV)",
        ylabel = "Expected Count per Energy Sample",
    )
    Mke.lines!(ax2, ENERGIES, S_LOW .* transmission; color = COLORS.cyan, label = "80 kVp")
    Mke.lines!(
        ax2,
        ENERGIES,
        S_HIGH .* transmission;
        color = COLORS.violet,
        label = "140 kVp",
    )
    Mke.axislegend(ax2; position = :rt)
    Mke.rowsize!(fig.layout, 1, Mke.Relative(0.3))
    fig
end

# ╔═╡ 4d445200-0000-4000-8000-000000000750
md"""
**Tin on the 140 kVp beam: $(tin_readout[1]) mm.** The bound of the iodine line integral is
**$(tin_readout[2]) mg/cm²** and the bound of the water line integral is **$(tin_readout[3]) g/cm²**.
The correlation between their errors is $(tin_readout[4]). Without the object, the high beam
delivers $(tin_readout[5]) photons to the detector element.
"""

# ╔═╡ 4d445200-0000-4000-8000-000000000751
let
    Mke.set_theme!(THEME)
    fig = Mke.Figure(size = (1400, 560))
    ax1 = Mke.Axis(
        fig[1, 1];
        title = "Noise Bound of the Iodine Line Integral",
        subtitle = "Ray Through 20 cm of Water, Fixed Tube Output",
        xlabel = "Tin on the 140 kVp Beam (mm)",
        ylabel = "Cramér–Rao Bound (mg/cm²)",
    )
    Mke.scatterlines!(
        ax1,
        TIN_SWEEP,
        1000 .* last.(BOUND_SWEEP);
        color = COLORS.green,
        markersize = 12,
    )
    Mke.vlines!(ax1, [BEST_TIN]; color = COLORS.muted, linestyle = :dash)
    ax2 = Mke.Axis(
        fig[1, 2];
        title = "The Two Beams at the Lowest Bound",
        subtitle = "80 kVp and 140 kVp Behind $(BEST_TIN) mm of Tin",
        xlabel = "Photon Energy (keV)",
        ylabel = "Expected Count per Energy Sample",
    )
    S = dual_energy(BEST_TIN)
    Mke.lines!(ax2, ENERGIES, S[1, :]; color = COLORS.cyan, label = "80 kVp")
    Mke.lines!(ax2, ENERGIES, S[2, :]; color = COLORS.violet, label = "140 kVp With Tin")
    Mke.axislegend(ax2; position = :rt)
    fig
end

# ╔═╡ 4d445200-0000-4000-8000-000000000752
let
    xs = Float64[]
    ys = Float64[]
    i = 1
    while i <= length(TIN_MM)
        push!(xs, TIN_MM[i])
        push!(ys, IODINE_BOUND_MG[i])
        i += 1
    end
    fig = WM.Figure(; size = (700, 380), backgroundcolor = (0.973, 0.969, 0.957, 1.0))
    ax = WM.Axis(
        fig[1, 1];
        title = "Bound of the Iodine Line Integral",
        xlabel = "Tin on the 140 kVp Beam (mm)",
        ylabel = "Bound (mg/cm²)",
    )
    WM.lines!(ax, xs, ys; linewidth = 2.5, color = (0.486, 0.227, 0.929, 1.0))
    WM.scatter!(
        ax,
        [TIN_MM[tin_tenths + 1]],
        [IODINE_BOUND_MG[tin_tenths + 1]];
        markersize = 14.0,
        color = (0.031, 0.569, 0.698, 1.0),
    )
    fig
end

# ╔═╡ 4d445200-0000-4000-8000-000000000760
let
    Mke.set_theme!(THEME)
    fig = Mke.Figure(size = (1400, 900))
    ladder!(canvas(fig[1, 1:3], (-8, 8, -4.2, 5.2)))
    colors = [COLORS.cyan, COLORS.violet, COLORS.green]
    for (j, (set, materials)) in enumerate(MATERIAL_SETS)
        ax = Mke.Axis(
            fig[2, j];
            title = "$(length(materials)) Materials",
            subtitle = set,
            xlabel = "Singular Value",
            ylabel = j == 1 ? "Share of the Largest" : "",
            yscale = log10,
            xticks = 1:4,
            subtitlesize = 14,
        )
        for (i, (acquisition, _)) in enumerate(ACQUISITIONS)
            ratios = LADDER[i, j].ratios
            Mke.scatterlines!(ax, 1:length(ratios), ratios;
                color = colors[i],
                markersize = (
                    24,
                    17,
                    11,
                )[i], # the largest first, so that coinciding points all show
                label = acquisition,
            )
        end
        Mke.hlines!(ax, [TOLERANCE]; color = COLORS.muted, linestyle = :dash)
        Mke.xlims!(ax, 0.5, 4.5)
        Mke.ylims!(ax, 1.0e-5, 3.0)
        j == 3 && Mke.Legend(fig[3, 1:3], ax; orientation = :horizontal)
    end
    Mke.rowsize!(fig.layout, 1, Mke.Relative(0.3))
    fig
end

# ╔═╡ 4d445200-0000-4000-8000-000000000761
Markdown.parse(
    """
| Acquisition | $(join([set for (set, _) in MATERIAL_SETS], " | ")) |
|:---|$(join(fill(":---:", length(MATERIAL_SETS)), "|"))|
$(join(["| $(ACQUISITIONS[i][1]) | " * join(["$(determined(LADDER[i, j])) of $(LADDER[i, j].n_materials)" for j in eachindex(MATERIAL_SETS)], " | ") * " |" for i in eachindex(ACQUISITIONS)], "\n"))

Each entry is the number of material amounts the acquisition determines at the 1% limit, of the
number the voxel is allowed to hold. Every material beyond that count has to be fixed by something
other than the voxel's own measurements: the conservation of volume, a library of allowed
mixtures, a spatial prior, or training data. The classes of the review differ in which of these
they use.
""",
)

# ╔═╡ 4d445200-0000-4000-8000-000000000770
Markdown.parse(
    """
### $(count(last, CHECKS)) of $(length(CHECKS)) Checks Pass

| Check | Value | Result |
|:---|---:|:---:|
$(join(["| $(name) | $(round(value; sigdigits = 3)) | $(pass ? "pass" : "CHECK") |" for (name, value, pass) in CHECKS], "\n"))
""",
)

# ╔═╡ 4d445200-0000-4000-8000-000000000780
let
    Mke.set_theme!(THEME)
    fig = Mke.Figure(size = (1200, 620))
    ax = Mke.Axis(
        fig[1, 1];
        title = "Papers on Material Decomposition in CT",
        subtitle = "PubMed Records per Year, $(first(CENSUS.year)) to $(last(CENSUS.year))",
        xlabel = "Year of Publication",
        ylabel = "Records",
    )
    Mke.lines!(ax, CENSUS.year, CENSUS.all; color = COLORS.violet, label = "All")
    Mke.lines!(
        ax,
        CENSUS.year,
        CENSUS.learned;
        color = COLORS.cyan,
        label = "Naming a Learning Method",
    )
    Mke.lines!(ax, CENSUS.year, CENSUS.review; color = COLORS.beam, label = "Reviews")
    Mke.axislegend(ax; position = :lt)
    Mke.save(joinpath(@__DIR__, "..", "paper", "figures", "fig_census.pdf"), fig)
    fig
end

# ╔═╡ 4d445200-0000-4000-8000-000000000781
Markdown.parse(
    """
The search found $(CENSUS.total_all) records from $(first(CENSUS.year)) to $(last(CENSUS.year)),
$(last(CENSUS.all)) of them in $(last(CENSUS.year)). Of all records, $(CENSUS.total_learned) name a
learning method and $(CENSUS.total_review) are listed as reviews.
""",
)

# ╔═╡ Cell order:
# ╟─4d445200-0000-4000-8000-000000000100
# ╟─4d445200-0000-4000-8000-000000000700
# ╟─4d445200-0000-4000-8000-000000000101
# ╟─4d445200-0000-4000-8000-000000000710
# ╟─4d445200-0000-4000-8000-000000000102
# ╠═4d445200-0000-4000-8000-000000000001
# ╠═4d445200-0000-4000-8000-000000000002
# ╠═4d445200-0000-4000-8000-000000000003
# ╠═4d445200-0000-4000-8000-000000000004
# ╠═4d445200-0000-4000-8000-000000000005
# ╠═4d445200-0000-4000-8000-000000000006
# ╠═4d445200-0000-4000-8000-000000000008
# ╟─4d445200-0000-4000-8000-000000000007
# ╟─4d445200-0000-4000-8000-000000000103
# ╠═4d445200-0000-4000-8000-000000000010
# ╠═4d445200-0000-4000-8000-000000000011
# ╠═4d445200-0000-4000-8000-000000000012
# ╠═4d445200-0000-4000-8000-000000000013
# ╟─4d445200-0000-4000-8000-000000000110
# ╠═4d445200-0000-4000-8000-000000000020
# ╠═4d445200-0000-4000-8000-000000000021
# ╠═4d445200-0000-4000-8000-000000000022
# ╟─4d445200-0000-4000-8000-000000000720
# ╟─4d445200-0000-4000-8000-000000000111
# ╠═4d445200-0000-4000-8000-000000000030
# ╠═4d445200-0000-4000-8000-000000000031
# ╠═4d445200-0000-4000-8000-000000000032
# ╠═4d445200-0000-4000-8000-000000000033
# ╠═4d445200-0000-4000-8000-000000000034
# ╟─4d445200-0000-4000-8000-000000000730
# ╟─4d445200-0000-4000-8000-000000000731
# ╟─4d445200-0000-4000-8000-000000000112
# ╠═4d445200-0000-4000-8000-000000000040
# ╠═4d445200-0000-4000-8000-000000000041
# ╠═4d445200-0000-4000-8000-000000000042
# ╠═4d445200-0000-4000-8000-000000000043
# ╠═4d445200-0000-4000-8000-000000000044
# ╠═4d445200-0000-4000-8000-000000000045
# ╠═4d445200-0000-4000-8000-000000000046
# ╠═4d445200-0000-4000-8000-000000000047
# ╠═4d445200-0000-4000-8000-000000000048
# ╠═4d445200-0000-4000-8000-000000000050
# ╠═4d445200-0000-4000-8000-000000000051
# ╠═4d445200-0000-4000-8000-000000000052
# ╠═4d445200-0000-4000-8000-000000000053
# ╠═4d445200-0000-4000-8000-000000000054
# ╠═4d445200-0000-4000-8000-000000000055
# ╠═4d445200-0000-4000-8000-000000000056
# ╟─4d445200-0000-4000-8000-000000000740
# ╟─4d445200-0000-4000-8000-000000000113
# ╠═4d445200-0000-4000-8000-000000000060
# ╠═4d445200-0000-4000-8000-000000000061
# ╠═4d445200-0000-4000-8000-000000000062
# ╠═4d445200-0000-4000-8000-000000000063
# ╠═4d445200-0000-4000-8000-000000000064
# ╟─4d445200-0000-4000-8000-000000000066
# ╟─4d445200-0000-4000-8000-000000000067
# ╟─4d445200-0000-4000-8000-000000000068
# ╟─4d445200-0000-4000-8000-000000000750
# ╟─4d445200-0000-4000-8000-000000000752
# ╟─4d445200-0000-4000-8000-000000000751
# ╟─4d445200-0000-4000-8000-000000000114
# ╠═4d445200-0000-4000-8000-000000000070
# ╠═4d445200-0000-4000-8000-000000000071
# ╠═4d445200-0000-4000-8000-000000000072
# ╠═4d445200-0000-4000-8000-000000000073
# ╠═4d445200-0000-4000-8000-000000000074
# ╠═4d445200-0000-4000-8000-000000000075
# ╟─4d445200-0000-4000-8000-000000000760
# ╟─4d445200-0000-4000-8000-000000000761
# ╟─4d445200-0000-4000-8000-000000000118
# ╠═4d445200-0000-4000-8000-000000000085
# ╟─4d445200-0000-4000-8000-000000000780
# ╟─4d445200-0000-4000-8000-000000000781
# ╟─4d445200-0000-4000-8000-000000000115
# ╠═4d445200-0000-4000-8000-000000000079
# ╠═4d445200-0000-4000-8000-000000000080
# ╠═4d445200-0000-4000-8000-000000000081
# ╟─4d445200-0000-4000-8000-000000000116
# ╠═4d445200-0000-4000-8000-000000000090
# ╟─4d445200-0000-4000-8000-000000000770
# ╟─4d445200-0000-4000-8000-000000000117
