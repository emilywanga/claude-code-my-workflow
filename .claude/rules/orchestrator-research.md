---
paths:
  - "Code/**/*.R"
  - "Code/**/*.py"
  - "Code/**/*.do"
  - "scripts/**/*.R"
  - "explorations/**"
---

# Research Project Orchestrator

**For data analysis scripts (R, Python, Stata) and explorations** — use this simplified loop.

## The Simple Loop

```text
Plan approved → orchestrator activates
  │
  Step 1: IMPLEMENT — Execute plan steps
  │
  Step 2: VERIFY — Run code, check outputs
  │         R:      Rscript runs without error; output files created
  │         Python: python script.py runs without error; outputs created
  │         Stata:  .do file runs without error; outputs created
  │         Spatial: CRS verified; no silent mismatches
  │         If verification fails → fix → re-verify
  │
  Step 3: SCORE — Apply quality-gates rubric
  │
  └── Score >= 80?
        YES → Done (commit when user signals)
        NO  → Fix blocking issues, re-verify, re-score
```

**No 5-round loops. No multi-agent reviews. Just: write, test, done.**

---

## Verification Checklist

### All Scripts

- [ ] Script runs without errors
- [ ] All packages/imports at top
- [ ] No hardcoded absolute paths
- [ ] Output files created at expected paths
- [ ] Quality score >= 80

### R Scripts

- [ ] `set.seed()` once at top if stochastic
- [ ] Figures saved to `Results/Figures/` with explicit dimensions and `bg = "white"`
- [ ] Tables saved to `Results/Tables/` as `.tex` and `.csv`

### Python Scripts (Geodata)

- [ ] `random_state=` set for any stochastic operation
- [ ] CRS set and verified before every spatial join
- [ ] Large raster files closed after reading (avoid memory leaks)
- [ ] Processed data saved to `Data/processed/`

### Stata Scripts

- [ ] `set seed` at top
- [ ] `global root` defined for path portability
- [ ] Tables exported to `Results/Tables/`
- [ ] No implicit factor variable coding

---

## Tolerance Checks (If Applicable)

- Point estimates: match within 1e-6
- Standard errors: match within 1e-4
- Coverage rates: within ± 0.01
