# The page's chrome: one small glass capsule floating over the notebook (title, contents, paper,
# GitHub, light/dark), the table-of-contents rail of wide windows, and a one-line footer.
#
# The capsule, its pills, the rail and its scroll-spy are ported from the docs of
# BasisSimulator.jl (MIT, MolloiLab; docs/src/components/Layout.jl and TableOfContents.jl), cut
# down to a single page.

const GITHUB_ICON = """<svg class="w-[18px] h-[18px]" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/></svg>"""

const PAPER_ICON = """<svg class="w-[17px] h-[17px]" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M14 3H7a2 2 0 00-2 2v14a2 2 0 002 2h10a2 2 0 002-2V8z"/><path d="M14 3v5h5M9 13h6M9 17h6"/></svg>"""

const CONTENTS_ICON = """<svg class="w-[18px] h-[18px]" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" aria-hidden="true"><path d="M4 7h16M4 12h16M4 17h10"/></svg>"""

# Marks the section being read in every list of contents, and closes the contents menu after a
# choice, a click elsewhere, or Escape. Plain script: nothing here needs hydration.
const PAGE_JS = """<script>(function(){
function spy(){var links=[].slice.call(document.querySelectorAll('[data-toc-link]'));if(!links.length||!('IntersectionObserver' in window))return;var byId={};links.forEach(function(a){var id=decodeURIComponent(a.getAttribute('href').slice(1));(byId[id]=byId[id]||[]).push(a);});var heads=Object.keys(byId).map(function(id){return document.getElementById(id);}).filter(Boolean);var vis=new Set();function mark(){var top=null;heads.forEach(function(h){if(vis.has(h)&&(!top||h.getBoundingClientRect().top<top.getBoundingClientRect().top))top=h;});if(!top){var y=window.innerHeight*0.3;heads.forEach(function(h){if(h.getBoundingClientRect().top<y)top=h;});}links.forEach(function(a){a.removeAttribute('data-active');});if(top)byId[top.id].forEach(function(a){a.setAttribute('data-active','');});}var io=new IntersectionObserver(function(es){es.forEach(function(e){e.isIntersecting?vis.add(e.target):vis.delete(e.target);});mark();},{rootMargin:'-80px 0px -55% 0px'});heads.forEach(function(h){io.observe(h);});mark();}
function menu(){var m=document.querySelector('[data-contents-menu]');if(!m)return;document.addEventListener('click',function(e){if(m.open&&(!m.contains(e.target)||e.target.closest('[data-contents-menu] a')))m.removeAttribute('open');});document.addEventListener('keydown',function(e){if(e.key==='Escape'&&m.open){m.removeAttribute('open');var s=m.querySelector('summary');if(s)s.focus();}});}
function run(){spy();menu();}
document.readyState==='loading'?document.addEventListener('DOMContentLoaded',run):run();
})();</script>"""

"The links of a list of contents, one per section: `(id, label, depth)`."
function toc_links(sections)
    return [
        A(
            :href => "#$(id)",
            Symbol("data-toc-link") => "",
            Symbol("data-depth") => string(depth),
            :class => "mdr-toc-link",
            label,
        )
        for (id, label, depth) in sections
    ]
end

"The contents rail beside the notebook: a column of its own in wide windows, hidden below them."
function TableOfContents(sections)
    return Nav(
        Symbol("aria-label") => "Contents",
        :class =>
            "hidden xl:block sticky top-24 self-start max-h-[calc(100vh-8rem)] overflow-y-auto pt-10",
        P(:class => "mdr-eyebrow pb-3", "Contents"),
        toc_links(sections)...,
    )
end

"The contents menu in the capsule, for windows too narrow for the rail. It opens under the capsule."
function ContentsMenu(sections)
    return Details(
        Symbol("data-contents-menu") => "",
        :class => "xl:hidden",
        Summary(
            Symbol("aria-label") => "Contents",
            :title => "Contents",
            :class => "mdr-pill mdr-pill-icon cursor-pointer",
            RawHtml(CONTENTS_ICON),
        ),
        Div(
            :class =>
                "mdr-menu absolute right-0 top-full mt-2 w-[min(20rem,100%)] max-h-[70vh] overflow-y-auto p-4",
            P(:class => "mdr-eyebrow pb-3", "Contents"),
            toc_links(sections)...,
        ),
    )
end

function Layout(content)
    sections = notebook_sections(notebook_html())
    return Div(
        :id => "top",
        :class => "min-h-screen flex flex-col text-[var(--ink)]",
        # EB Garamond's italics and heavier weights (Therapy's shell loads the roman and one
        # italic), JetBrains Mono where JuliaMono is not installed, and KaTeX for the notebook's
        # math: the fragment renders its formulas with the KaTeX the page provides.
        RawHtml(
            """<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=EB+Garamond:ital,wght@0,400..800;1,400..800&family=JetBrains+Mono:wght@400;500&display=swap"><link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.11.1/dist/katex.min.css"><script defer src="https://cdn.jsdelivr.net/npm/katex@0.11.1/dist/katex.min.js"></script>""",
        ),
        Header(
            :class => "mdr-top sticky top-0 z-40 px-3 sm:px-6 pt-3 sm:pt-4 pb-3",
            Div(
                :class =>
                    "mdr-bar max-w-[58rem] xl:max-w-[76rem] mx-auto h-[3.25rem] pl-5 pr-2 flex items-center justify-between gap-2",
                A(
                    :href => "#top",
                    :class => "mdr-title min-w-0",
                    "Material Decomposition",
                    Span(:class => "hidden min-[420px]:inline", " ", Em("in"), " CT"),
                ),
                Nav(
                    Symbol("aria-label") => "Page",
                    :class => "flex items-center gap-0.5 shrink-0",
                    ContentsMenu(sections),
                    A(
                        :href => PAPER_URL,
                        :target => "_blank",
                        :rel => "noopener",
                        Symbol("aria-label") => "The paper",
                        :title => "The paper",
                        :class => "mdr-pill max-sm:w-9 max-sm:px-0",
                        RawHtml(PAPER_ICON),
                        Span(:class => "hidden sm:inline", "Paper"),
                    ),
                    A(
                        :href => REPO_URL,
                        :target => "_blank",
                        :rel => "noopener",
                        Symbol("aria-label") => "The repository on GitHub",
                        :title => "GitHub",
                        :class => "mdr-pill mdr-pill-icon",
                        RawHtml(GITHUB_ICON),
                    ),
                    DarkModeToggle(),
                ),
            ),
        ),
        # id="page-content": Therapy's router expects it, and the notebook's styles start there.
        MainEl(
            :id => "page-content",
            :class => "flex-1 w-full px-3 sm:px-6 pt-4 sm:pt-8 pb-16",
            content,
        ),
        Footer(
            :class => "px-4 sm:px-6 pb-10",
            Div(
                :class =>
                    "mdr-foot max-w-[58rem] xl:max-w-[76rem] mx-auto pt-5 flex flex-wrap gap-x-6 gap-y-1 items-center justify-center",
                A(
                    :href => "https://github.com/MolloiLab",
                    :target => "_blank",
                    "MolloiLab",
                ),
                A(
                    :href => "https://github.com/MolloiLab/BasisSimulator.jl",
                    :target => "_blank",
                    "Simulated with BasisSimulator.jl",
                ),
                A(
                    :href => "https://github.com/GroupTherapyOrg/Snapshot.jl",
                    :target => "_blank",
                    "Exported by Snapshot.jl",
                ),
                A(
                    :href => "https://github.com/GroupTherapyOrg/Therapy.jl",
                    :target => "_blank",
                    "Built with Therapy.jl",
                ),
            ),
        ),
        RawHtml(PAGE_JS),
    )
end
