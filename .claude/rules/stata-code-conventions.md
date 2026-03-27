---
paths:
  - "Code/Stata/**/*.do"
  - "scripts/**/*.do"
---

# Stata Code Standards

**Standard:** Replication-ready, AEA Data and Code Policy compliant

---

## 1. Reproducibility

- `set seed` called once at top (use YYYYMMDD integer format)
- `version 17` (or relevant version) declared at top
- `set more off` at top
- All paths defined via `global root` — never hardcode absolute paths

```stata
* ==============================================================
* Script: descriptive_name.do
* Purpose: [what this script does]
* Inputs:  Data/processed/input_file.dta
* Outputs: Results/Tables/table_name.tex
* ==============================================================

version 17
set more off
set seed 20230101

* --- Path globals (set root to repo directory) ---
global root   "[REPO_ROOT]"        // set this in master.do
global data   "$root/Data/processed"
global tables "$root/Results/Tables"
global figs   "$root/Results/Figures"
```

**Use a `master.do`** that sets `global root` and calls all scripts in order.

## 2. Output Conventions

- Tables → `$tables/` as `.tex` (use `esttab`, `outreg2`, or `regsave`)
- Figures → `$figs/` as `.pdf` or `.png`
- Never print results to log and copy-paste into paper

```stata
* Export regression table
esttab m1 m2 m3 using "$tables/main_results.tex", ///
    replace booktabs label ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    title("Main Results") ///
    nonotes addnotes("Standard errors clustered at county level.")
```

## 3. Panel and Spatial Data

- Always `xtset panelvar timevar` before panel commands; verify balanced vs unbalanced
- Cluster standard errors at the right level: `vce(cluster county_id)`
- For staggered DiD: use `csdid` (Callaway-Sant'Anna) or `eventstudyinteract` (Sun-Abraham)
- For spatial autocorrelation: use `acreg` or Conley SEs

```stata
* Staggered DiD (Callaway-Sant'Anna)
csdid outcome, ivar(county_id) tvar(year) gvar(first_treat_year) ///
    method(dripw) wboot

* Conley standard errors (spatial)
acreg outcome treatment controls, ///
    spatial latitude(lat) longitude(lon) dist(100)
```

## 4. Factor Variables and Interactions

- Always use factor variable notation: `i.year` not dummy variables
- Interact with `##`: `treatment##i.year`
- Absorb high-dimensional FE with `reghdfe`

```stata
reghdfe outcome treatment controls, ///
    absorb(county_id year) ///
    vce(cluster county_id)
```

## 5. Common Pitfalls

| Pitfall | Impact | Prevention |
|---------|--------|------------|
| Hardcoded paths | Breaks on other machines | Always use `$root` globals |
| Missing `set seed` | Non-reproducible bootstrap | Add at top of every script |
| Wrong cluster level | Incorrect SEs | Match cluster to treatment assignment level |
| TWFE with staggered timing | Negative weights | Use `csdid` or `eventstudyinteract` |
| No `version` statement | Different results across Stata versions | Always declare version |
| `if year==X` instead of `if year==X & !missing(var)` | Wrong sample | Always handle missing explicitly |

## 6. Code Quality Checklist

```text
[ ] version declaration at top
[ ] set more off; set seed at top
[ ] All paths via $root globals
[ ] master.do runs all scripts in correct order
[ ] Tables exported with esttab/outreg2 to $tables/
[ ] Figures exported to $figs/
[ ] Cluster level documented in comments
[ ] Factor variables used (i.var, ##)
[ ] Panel data: xtset verified
[ ] No magic numbers — use local macros
```
