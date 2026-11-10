#!/usr/bin/env python3
"""Count the CT material-decomposition papers in PubMed for each year (Fig. 1 of the paper).

    python3 scripts/literature_census.py > results/literature_census.csv

Four counts per year: every paper whose title or abstract names material or basis decomposition in CT,
those that name it in the title, those that also name a learning method, and those PubMed lists as
reviews. The queries are printed at the end of the file, so the counts can be reproduced. The counts
change as PubMed indexes more papers, so the date of the run is recorded too.
"""
import datetime
import json
import sys
import time
import urllib.parse
import urllib.request

ESEARCH = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&retmode=json&retmax=0&term="
FIRST_YEAR, LAST_YEAR = 1976, 2025  # from Alvarez and Macovski to the last complete year

CT = '(CT[Title/Abstract] OR "computed tomography"[Title/Abstract] OR tomograph*[Title/Abstract])'
DECOMPOSITION = ('("material decomposition"[Title/Abstract] OR "basis decomposition"[Title/Abstract] OR '
                 '"basis material"[Title/Abstract] OR "multi-material decomposition"[Title/Abstract] OR '
                 '"multimaterial decomposition"[Title/Abstract])')
QUERIES = {
    "all": f"{DECOMPOSITION} AND {CT}",
    "title": ('("material decomposition"[Title] OR "basis decomposition"[Title] OR '
              '"multi-material decomposition"[Title] OR "multimaterial decomposition"[Title]) AND ' + CT),
    "learned": (f"{DECOMPOSITION} AND {CT} AND (\"deep learning\"[Title/Abstract] OR "
                '"neural network"[Title/Abstract] OR "neural networks"[Title/Abstract] OR '
                '"machine learning"[Title/Abstract] OR diffusion[Title/Abstract])'),
    "review": f"{DECOMPOSITION} AND {CT} AND review[Publication Type]",
}


def count(term):
    for _ in range(4):
        try:
            with urllib.request.urlopen(ESEARCH + urllib.parse.quote(term), timeout=40) as response:
                return int(json.load(response)["esearchresult"]["count"])
        except Exception:  # PubMed limits the request rate; wait and ask again
            time.sleep(3)
    raise SystemExit(f"PubMed did not answer for: {term}")


def main():
    print("year," + ",".join(QUERIES))
    for year in range(FIRST_YEAR, LAST_YEAR + 1):
        print(f"{year}," + ",".join(str(count(f"({query}) AND {year}[pdat]")) for query in QUERIES.values()))
        sys.stdout.flush()
        time.sleep(0.35)
    totals = ",".join(str(count(f"({query}) AND {FIRST_YEAR}:{LAST_YEAR}[pdat]")) for query in QUERIES.values())
    print(f"#total,{totals}")
    print(f"#run,{datetime.date.today().isoformat()}")
    for name, query in QUERIES.items():
        print(f'#query_{name},"{query}"')


if __name__ == "__main__":
    main()
