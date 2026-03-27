---
paths:
  - "Paper/**/*.tex"
  - "Slides/**/*.tex"
  - "Code/**/*.R"
  - "Code/**/*.py"
  - "Code/**/*.do"
  - "scripts/**/*.R"
---

# Quality Gates & Scoring Rubrics

## Thresholds

- **80/100 = Commit** — good enough to save
- **90/100 = PR** — ready for sharing/submission
- **95/100 = Excellence** — journal-ready

---

## LaTeX Paper (.tex — manuscript)

| Severity | Issue | Deduction |
|----------|-------|-----------|
| Critical | XeLaTeX compilation failure | -100 |
| Critical | Undefined citation key | -15 |
| Critical | Broken cross-reference (`??`) | -10 |
| Critical | Equation typo | -10 |
| Major | Overfull hbox > 10pt | -5 |
| Major | Notation inconsistency | -5 |
| Major | Table misalignment or overrun | -5 |
| Major | Orphaned footnote (no matching ref) | -3 |
| Minor | Underfull hbox | -1 |
| Minor | Long lines in comments (>100 chars) | -1 |

---

## R Scripts (.R)

| Severity | Issue | Deduction |
|----------|-------|-----------|
| Critical | Syntax errors | -100 |
| Critical | Hardcoded absolute paths | -20 |
| Critical | CRS mismatch in spatial join | -20 |
| Major | Missing `set.seed()` | -10 |
| Major | Missing output files (figures/tables) | -10 |
| Major | Cluster SE applied to wrong level | -10 |
| Minor | Lines > 100 chars (non-math) | -1 per line |
| Minor | Missing Roxygen documentation | -2 |

---

## Python Scripts (.py — geodata)

| Severity | Issue | Deduction |
|----------|-------|-----------|
| Critical | Syntax / runtime errors | -100 |
| Critical | Hardcoded absolute paths | -20 |
| Critical | CRS not set before spatial operation | -20 |
| Critical | Spatial join without CRS verification | -15 |
| Major | Missing output files | -10 |
| Major | No `random_state=` for stochastic ops | -10 |
| Major | Memory leak (large rasters not closed) | -5 |
| Minor | Missing imports at top of file | -3 |
| Minor | Lines > 100 chars (non-math) | -1 per line |

---

## Stata Scripts (.do)

| Severity | Issue | Deduction |
|----------|-------|-----------|
| Critical | Do-file fails to run | -100 |
| Critical | Hardcoded absolute paths | -20 |
| Major | Missing `set seed` | -10 |
| Major | Factor variable coding error | -10 |
| Major | Wrong cluster level for SE | -10 |
| Minor | Missing `global root` setup | -5 |
| Minor | No version declaration | -2 |

---

## Beamer Slides (.tex — presentations)

| Severity | Issue | Deduction |
|----------|-------|-----------|
| Critical | XeLaTeX compilation failure | -100 |
| Critical | Undefined citation | -15 |
| Critical | Overfull hbox > 10pt | -10 |

---

## Enforcement

- **Score < 80:** Block commit. List blocking issues.
- **Score < 90:** Allow commit, warn. List recommendations.
- User can override with justification.

## Quality Reports

Generated **only at merge time**. Use `templates/quality-report.md` for format.
Save to `quality_reports/merges/YYYY-MM-DD_[branch-name].md`.

---

## Tolerance Thresholds (Econometrics)

| Quantity | Tolerance | Rationale |
|----------|-----------|-----------|
| Point estimates | 1e-6 | Numerical precision across languages |
| Standard errors | 1e-4 | Acceptable MC variability |
| Coverage rates | ± 0.01 | MC with B = 1000 replications |
| Spatial weights | 1e-8 | Row-normalization precision |
