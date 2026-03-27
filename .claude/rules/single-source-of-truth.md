---
paths:
  - "Paper/**/*.tex"
  - "Results/**"
  - "Code/**"
  - "Figures/**"
---

# Single Source of Truth: Enforcement Protocol

**`Paper/main.tex` is the authoritative artifact.** All tables and figures flow into it from code.

## The SSOT Chain

```text
Raw data (external / Data/raw/ — gitignored)
  │
  ↓  Code/Python/  (geodata cleaning, satellite processing)
  │
Data/processed/  (committed small datasets)
  │
  ↓  Code/R/ or Code/Stata/  (econometric analysis)
  │
Results/Tables/  (generated .tex tables)
Results/Figures/ (generated .pdf/.png figures)
  │
  ↓  \input{} / \includegraphics{} in Paper/
  │
Paper/main.tex  ← SOURCE OF TRUTH
  │
  └── Paper/main.pdf  (compiled output — derived)
```

**NEVER edit tables or figures in `Results/` by hand.**
**ALWAYS regenerate from code.**

---

## Data Provenance Protocol (MANDATORY)

Before any empirical results appear in the paper, verify:

1. The generating script exists in `Code/` and runs clean
2. The output lands in `Results/Tables/` or `Results/Figures/`
3. The `\input{}` or `\includegraphics{}` path in `Paper/` matches exactly
4. The script has `set.seed()` or `random_state=` for any stochastic step

---

## Results Freshness Protocol

**Before citing a number in the paper, verify it matches the current code output.**

### Diff-Check Procedure

1. Identify the table/figure referenced in the paper
2. Find the generating script in `Code/`
3. Confirm the script was run after the last data or specification change
4. If uncertain: re-run the script, check the output matches what's in the paper

### When to Regenerate All Results

- After any change to `Data/processed/`
- After any change to the sample definition
- After any change to the econometric specification
- Before any submission or major revision

---

## Content Fidelity Checklist (Before Submission)

```text
[ ] All tables in paper have a generating script in Code/
[ ] All figures in paper have a generating script in Code/
[ ] No number in the paper was typed manually (all from \input or \num{})
[ ] Bibliography_base.bib has every cited reference
[ ] No \cite{} keys missing from .bib
[ ] Data/processed/ files match what scripts expect
[ ] Paper compiles clean (no undefined references, no overfull hbox > 10pt)
```

---

## Conference Slides (Secondary Artifact)

Slides in `Slides/` are a secondary artifact derived from the paper.

```text
Paper/main.tex  (source)
  └── Slides/slides.tex  (derived — must not add unreported results)
```

- Never present results in slides that haven't been verified in the paper
- Slide figures should be the same files as `Results/Figures/` (or copies)
