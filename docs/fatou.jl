# Fatou for the cells of the Pluto notebooks, which `fatou format` cannot format as files.
#
#     julia docs/fatou.jl                  # check: show what would change, exit 1 if anything would
#     julia docs/fatou.jl --write          # format in place
#     julia docs/fatou.jl --write <files or folders>
#
# Pluto rewrites its header (the `@bind` mock), its `# ╔═╡` markers, the package cells and the
# Cell order block on every save, so `fatou.toml` keeps Fatou's own walk out of `notebooks/` and
# each cell's code is formatted here, alone. Disabled cells and the package cells are left as they
# are. Every cell goes through `fatou format -` with the repository's `fatou.toml`; a cell Fatou
# cannot parse fails the check. Lint the notebooks by name: `fatou lint notebooks/*.jl`.
# Needs only Julia and `fatou` on the PATH.
#
# Ported from docs/fatou.jl of BasisSimulator.jl (MIT, MolloiLab), reduced to the notebook cells.

const ROOT = dirname(@__DIR__)
const NOTEBOOK_DIRS = ["notebooks"]

const MARKER = r"^# ╔═╡ ([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})$"
const PACKAGE_CELLS = (
    "00000000-0000-0000-0000-000000000001",
    "00000000-0000-0000-0000-000000000002",
)

"""Fatou's formatting of `code`, or `nothing` and its message when it cannot parse it."""
function fatou(code::AbstractString)
    out = IOBuffer()
    err = IOBuffer()
    proc = run(pipeline(
        ignorestatus(Cmd(`fatou format -`; dir = ROOT));
        stdin = IOBuffer(code),
        stdout = out,
        stderr = err,
    ))
    success(proc) || return nothing, String(take!(err))
    return String(take!(out)), ""
end

"""
`(new_text, changed, failures)` for a notebook: each cell's code formatted alone.
`changed` lists `(label, old, new)`; `failures` lists `(label, error)`.
"""
function format_notebook(text)
    lines = split(text, '\n')
    out = String[]
    changed = Tuple{String, String, String}[]
    failures = Tuple{String, String}[]
    i = 1
    while i <= length(lines)
        m = match(MARKER, lines[i])
        if m === nothing
            push!(out, lines[i])
            i += 1
            continue
        end
        cell = m.captures[1]
        push!(out, lines[i])
        i += 1
        meta = String[]
        while i <= length(lines) && startswith(lines[i], "# ╠═╡ ")
            push!(meta, lines[i])
            i += 1
        end
        append!(out, meta)
        j = i
        while j <= length(lines) && !startswith(lines[j], "# ╔═╡ ")
            j += 1
        end
        body = lines[i:(j - 1)]
        # the code, then the blank line(s) Pluto writes before the next marker
        trailing = 0
        while !isempty(body) && body[end] == ""
            pop!(body)
            trailing += 1
        end
        code = join(body, '\n')
        skip = cell in PACKAGE_CELLS ||
            any(x -> occursin("disabled = true", x), meta) ||
            startswith(code, "#=╠═╡")
        new = code
        if !skip && !isempty(strip(code))
            formatted, err = fatou(code * "\n")
            if formatted === nothing
                push!(failures, ("cell $(cell)", err))
            else
                new = rstrip(formatted, '\n')
                new == code || push!(changed, ("cell $(cell)", code, new))
            end
        end
        isempty(new) || append!(out, split(new, '\n'))
        append!(out, fill("", trailing))
        i = j
    end
    return join(out, '\n'), changed, failures
end

is_notebook(text) = startswith(text, "### A Pluto.jl notebook ###")

"""Every `.jl` file under `path` (or `path` itself)."""
function files_under(path)
    isfile(path) && return [path]
    isdir(path) || error("no such file or folder: $(path)")
    return sort!([
        joinpath(dir, f)
        for (dir, _, fs) in walkdir(path)
        for f in fs
        if endswith(f, ".jl")
    ])
end

"""A unified diff of `old` and `new` (through `diff`, if it is installed)."""
function show_diff(label, old, new)
    Sys.which("diff") === nothing && return println("  ", label)
    mktempdir() do dir
        a = joinpath(dir, "before.jl")
        b = joinpath(dir, "after.jl")
        write(a, old * "\n")
        write(b, new * "\n")
        diff = read(
            ignorestatus(`diff -u --label $(label) --label "$(label) (fatou)" $a $b`),
            String,
        )
        print(diff)
    end
    return nothing
end

function main(args)
    write_mode = "--write" in args
    given = [abspath(a) for a in args if !startswith(a, "--")]
    roots = isempty(given) ? [joinpath(ROOT, p) for p in NOTEBOOK_DIRS] : given
    paths = unique(reduce(
        vcat,
        (files_under(p) for p in roots if ispath(p));
        init = String[],
    ))
    n_files = 0
    n_cells = 0
    n_failed = 0
    for path in paths
        rel = relpath(path, ROOT)
        text = read(path, String)
        is_notebook(text) || continue
        new, changed, failures = format_notebook(text)
        for (label, err) in failures
            n_failed += 1
            println("$(rel): Fatou cannot parse $(label): $(first(split(err, '\n')))")
        end
        isempty(changed) && continue
        n_files += 1
        n_cells += length(changed)
        if write_mode
            write(path, new)
            println("formatted $(length(changed)) cell(s) of $(rel)")
        else
            println("would reformat $(length(changed)) cell(s) of $(rel)")
            for (label, old, fmt) in changed
                show_diff("$(rel) $(label)", old, fmt)
            end
        end
    end
    verb = write_mode ? "formatted" : "would reformat"
    failed = n_failed > 0 ? "; $(n_failed) cell(s) Fatou cannot parse" : ""
    println("$(n_cells) cell(s) in $(n_files) of $(length(paths)) file(s) $(verb)$(failed)")
    return n_failed > 0 || (n_cells > 0 && !write_mode) ? 1 : 0
end

# The result of the check is the exit status of the script, which CI reads.
Base.exit(main(ARGS))
