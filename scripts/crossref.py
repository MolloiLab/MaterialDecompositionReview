#!/usr/bin/env python3
"""Print a \\bibitem in the house style of paper/main_clean.tex from the Crossref record of a DOI.

    python3 scripts/crossref.py alvarez1976=10.1088/0031-9155/21/5/002 [key=doi ...]
    python3 scripts/crossref.py --search "Cong De Man Wang univariate optimization dual-energy CT"

No reference enters LITERATURE.md or the paper from memory: every entry is printed by this script
from the publisher's record, then read against the paper itself. A field Crossref does not hold
(pages of some e-first articles, SPIE article numbers) prints as \\pending{...} and is completed
from the publisher's page by hand.
"""
import json
import re
import sys
import time
import urllib.parse
import urllib.request

API = "https://api.crossref.org/works"
HEADERS = {"User-Agent": "reference-check/1.0"}

# Journal abbreviations as the lab's papers print them.
JOURNALS = {
    "Physics in Medicine and Biology": "Phys. Med. Biol.",
    "Medical Physics": "Med. Phys.",
    "IEEE Transactions on Medical Imaging": "IEEE Trans. Med. Imag.",
    "IEEE Transactions on Radiation and Plasma Medical Sciences": "IEEE Trans. Radiat. Plasma Med. Sci.",
    "IEEE Transactions on Biomedical Engineering": "IEEE Trans. Biomed. Eng.",
    "IEEE Transactions on Computational Imaging": "IEEE Trans. Comput. Imag.",
    "Radiology": "Radiology",
    "RadioGraphics": "RadioGraphics",
    "European Radiology": "Eur. Radiol.",
    "Journal of Computer Assisted Tomography": "J. Comput. Assist. Tomogr.",
    "Journal of X-Ray Science and Technology": "J. X-Ray Sci. Technol.",
    "Journal of Computational Physics": "J. Comput. Phys.",
    "American Journal of Roentgenology": "Amer. J. Roentgenol.",
    "Investigative Radiology": "Invest. Radiol.",
    "Medical Image Analysis": "Med. Image Anal.",
    "SPIE Proceedings": "Proc. SPIE",
}


def get(url):
    error = None
    for _ in range(3):
        try:
            request = urllib.request.Request(url, headers=HEADERS)
            with urllib.request.urlopen(request, timeout=40) as response:
                return json.load(response)
        except Exception as exception:  # network errors are retried, then reported
            error = exception
            time.sleep(2)
    raise SystemExit(f"Crossref did not answer for {url}: {error}")


def clean(text):
    text = re.sub(r"<[^>]+>", "", text or "").replace("&amp;", "&")
    for old, new in (("\u2010", "-"), ("\u2011", "-"), ("\u2013", "--"), ("\u2014", "--"),
                     ("\u2019", "'"), ("&", r"\&"), ("\u00df", r"{\ss}"),
                     ("\u00e9", r"\'e"), ("\u00f6", r"\"o"), ("\u00e7", r"\c{c}"), ("\u00e4", r"\"a"),
                     ("\u00fc", r"\"u"), ("\u00e8", r"\`e")):
        text = text.replace(old, new)
    return " ".join(text.split())


def initials(given):
    parts = re.split(r"[\s.]+", clean(given).replace("-", " -"))
    out = ""
    for part in (p for p in parts if p):
        out += ("-" + part[1] + "." if part.startswith("-") else ("~" if out else "") + part[0] + ".")
    return out


def authors(record):
    names = []
    for author in record.get("author", []):
        family = clean(author.get("family") or author.get("name", ""))
        given = author.get("given", "")
        if not given:
            # some old records hold the whole name in the family field: "R E Alvarez"
            parts = family.split()
            lead = [part for part in parts[:-1] if len(part.rstrip(".")) == 1 and part[0].isupper()]
            if lead and lead == parts[:len(lead)]:
                given, family = " ".join(lead), " ".join(parts[len(lead):])
        given = initials(given)
        names.append(f"{given} {family}".strip())
    if len(names) > 6:
        return ", ".join(names[:6]) + r", \emph{et al.}"
    if len(names) > 2:
        return ", ".join(names[:-1]) + ", and " + names[-1]
    return " and ".join(names)


def bibitem(key, record):
    container = clean((record.get("container-title") or [""])[0])
    journal = JOURNALS.get(container.replace(r"\&", "and"), container)
    year = (record.get("issued", {}).get("date-parts") or [[None]])[0][0]
    pages = record.get("page") or record.get("article-number")
    where = []
    if record.get("volume"):
        where.append(f"vol.~{record['volume']}")
    if record.get("issue"):
        where.append(f"no.~{record['issue']}")
    if pages:
        where.append(("pp. " if "-" in pages else "p. ") + pages.replace("-", "--"))
    else:
        where.append(r"\pending{pages}")
    title = clean((record.get("title") or [""])[0])
    return (f"\\bibitem{{{key}}}\n{authors(record)}, ``{title},'' \\emph{{{journal}}}, "
            f"{', '.join(where)}, {year}, doi: {record.get('DOI')}.")


def main(arguments):
    if arguments and arguments[0] == "--search":
        query = urllib.parse.quote(" ".join(arguments[1:]))
        for item in get(f"{API}?rows=5&query.bibliographic={query}")["message"]["items"]:
            year = (item.get("issued", {}).get("date-parts") or [[None]])[0][0]
            print(f"{item.get('DOI')} | {year} | {clean((item.get('title') or [''])[0])}")
        return
    for argument in arguments:
        key, doi = argument.split("=", 1)
        try:
            print(bibitem(key, get(f"{API}/{urllib.parse.quote(doi)}")["message"]))
        except SystemExit as failure:  # report the entry and go on to the next
            print(f"% NOT VERIFIED {key}: {failure}")
        print()
        time.sleep(0.15)


if __name__ == "__main__":
    main(sys.argv[1:])
