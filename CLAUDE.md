# CLAUDE.MD — When Monitoring Backfires: Land Misallocation in China

**Project:** When Monitoring Backfires: Multi-Tasking Bureaucrats and Land Misallocation in China
**Institution:** The University Of Tokyo
**Branch:** main

---

## Core Principles

- **Plan first** — enter plan mode before non-trivial tasks; save plans to `quality_reports/plans/`
- **Verify after** — compile/run and confirm output at the end of every task
- **Single source of truth** — `Paper/main.tex` is authoritative; code outputs flow into it
- **Reproducibility** — all results must be regenerable from code; no manual edits to tables/figures
- **Quality gates** — nothing ships below 80/100
- **[LEARN] tags** — when corrected, save `[LEARN:category] wrong → right` to MEMORY.md

---

## Folder Structure

```text
project/
├── Paper/              ← LaTeX manuscript (main.tex, sections/, appendix/)
├── Code/
│   ├── Python/         ← geodata cleaning (satellite, shapefiles, soil)
│   ├── R/              ← econometric analysis, figures, tables
│   └── Stata/          ← Stata scripts (cross-check, legacy)
├── Results/
│   ├── Tables/         ← output tables (.tex, .csv) — generated, not edited
│   └── Figures/        ← output figures (.pdf, .png) — generated, not edited
├── Data/
│   ├── processed/      ← small processed datasets (committed)
│   └── raw/            ← raw satellite/admin data (gitignored)
├── Figures/            ← maps and static visuals checked into git
├── Slides/             ← conference/seminar presentations
├── Bibliography_base.bib
├── Preambles/          ← LaTeX preamble files
├── master_supporting_docs/
├── quality_reports/    ← plans, session logs, specs, merge reports
├── scripts/            ← utility scripts
└── templates/          ← session log, quality report templates
```

---

## Commands

```bash
# LaTeX paper (3-pass XeLaTeX)
cd Paper && TEXINPUTS=../Preambles:$TEXINPUTS xelatex -interaction=nonstopmode main.tex
BIBINPUTS=..:$BIBINPUTS bibtex main
TEXINPUTS=../Preambles:$TEXINPUTS xelatex -interaction=nonstopmode main.tex
TEXINPUTS=../Preambles:$TEXINPUTS xelatex -interaction=nonstopmode main.tex

# LaTeX conference slides (Beamer)
cd Slides && TEXINPUTS=../Preambles:$TEXINPUTS xelatex -interaction=nonstopmode slides.tex
BIBINPUTS=..:$BIBINPUTS bibtex slides
TEXINPUTS=../Preambles:$TEXINPUTS xelatex -interaction=nonstopmode slides.tex
TEXINPUTS=../Preambles:$TEXINPUTS xelatex -interaction=nonstopmode slides.tex

# Python geodata
cd Code/Python && python script_name.py

# R analysis
Rscript Code/R/script_name.R

# Stata
stata -b do Code/Stata/script_name.do
```

---

## Quality Thresholds

| Score | Gate | Meaning |
|-------|------|---------|
| 80 | Commit | Good enough to save |
| 90 | PR | Ready for submission/sharing |
| 95 | Excellence | Journal-ready |

---

## Skills Quick Reference

| Command | What It Does |
|---------|-------------|
| `/compile-latex [file]` | 3-pass XeLaTeX + bibtex |
| `/review-paper [file]` | Full manuscript review (AER/QJE standard) |
| `/review-r [file]` | R code quality review |
| `/data-analysis [dataset]` | End-to-end R analysis workflow |
| `/lit-review [topic]` | Literature search + synthesis |
| `/research-ideation [topic]` | Research questions + empirical strategies |
| `/interview-me [topic]` | Interactive research interview |
| `/validate-bib` | Cross-reference citations in paper |
| `/proofread [file]` | Grammar/typo review |
| `/compile-latex [file]` | Compile Beamer slides |
| `/visual-audit [file]` | Slide layout audit (for presentations) |
| `/commit [msg]` | Stage, commit, PR, merge |
| `/learn [skill-name]` | Extract discovery into persistent skill |
| `/context-status` | Show session health + context usage |
| `/deep-audit` | Repository-wide consistency audit |

---

## LaTeX Custom Commands

| Command | Effect | Use Case |
|---------|--------|----------|
| `[add as needed]` | | |

---

## Paper Status

| Component | File | Status | Notes |
|-----------|------|--------|-------|
| Main wrapper | `Paper/main.tex` | Active | Compiles with xelatex from Paper/ |
| Introduction | `Paper/sections/1_intro.tex` | Draft | |
| Institutional Background | `Paper/sections/2_background.tex` | Draft | |
| Data and Measurement | `Paper/sections/3_data.tex` | Draft | |
| Motivating Facts | `Paper/sections/4_fact.tex` | Draft | |
| Conceptual Framework | `Paper/sections/5_concept.tex` | Draft | |
| Empirical Analysis | `Paper/sections/6_empirical.tex` | Draft | |
| Discussion and Conclusion | `Paper/sections/7_conclusion.tex` | Draft | |
| Appendix | `Paper/appendix/A1_appendix.tex` | Draft | |

---

## Key Identification Details

- **Policy shock:** 2017 tightening of cropland protection enforcement (binding in evaluations)
- **Variation:** Cross-county differential exposure to binding cropland constraints within prefectures
- **Weak monitoring:** Land quality and utilization monitored weakly; area target monitored strictly
- **Data:** High-resolution satellite (land cover, vegetation), soil suitability, admin boundaries
- **Main findings:** Stricter enforcement → cropland expansion but lower quality + higher fallow rates
- **Heterogeneity:** Stronger when officials face higher promotion incentives + growth pressures
- **Target journals:** AER, QJE, JPub, AEJ:Policy, JDE
