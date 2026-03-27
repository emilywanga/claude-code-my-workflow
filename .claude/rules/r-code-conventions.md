---
paths:
  - "**/*.R"
  - "Code/R/**/*.R"
  - "scripts/**/*.R"
---

# R Code Standards

**Standard:** Senior Principal Data Engineer + PhD researcher quality

---

## 1. Reproducibility

- `set.seed()` called ONCE at top (YYYYMMDD format)
- All packages loaded at top via `library()` (not `require()`)
- All paths relative to repository root
- `dir.create(..., recursive = TRUE)` for output directories

## 2. Function Design

- `snake_case` naming, verb-noun pattern
- Roxygen-style documentation
- Default parameters, no magic numbers
- Named return values (lists or tibbles)

## 3. Domain Correctness (Land Use Econometrics)

- Always verify CRS matches before merging spatial objects with R (`sf` package)
- Cluster standard errors at the appropriate administrative level (county, prefecture)
- Spatial autocorrelation: check Moran's I before assuming independence
- Panel data: verify balanced vs unbalanced; document explicitly
- Event study: pre-trend tests must use coefficient plots, not just Wald tests
- Satellite indices (NDVI, EVI): verify band order matches sensor documentation
- Treatment timing: 2017 policy is staggered — use staggered DiD-robust estimators if needed

## 4. Visual Identity (Publication Figures)

```r
# --- Academic palette (publication-ready, colorblind-friendly) ---
navy      <- "#1a3a5c"   # primary color
charcoal  <- "#3d3d3d"   # secondary
gold      <- "#c9a84c"   # accent
green     <- "#2d7a4b"   # positive / treatment
red       <- "#b91c1c"   # negative / control
gray_mid  <- "#8a8a8a"   # muted / reference
```

### Custom Theme

```r
theme_paper <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title    = element_text(face = "bold", color = navy, size = base_size + 1),
      axis.title    = element_text(color = charcoal),
      axis.text     = element_text(color = charcoal),
      legend.position = "bottom",
      panel.grid.minor = element_blank(),
      plot.background  = element_rect(fill = "white", color = NA)
    )
}
```

### Figure Dimensions for Paper

```r
# Single-column figure (journal default)
ggsave(filepath, width = 6.5, height = 4.5, dpi = 300, bg = "white")

# Full-width figure (two-column layout)
ggsave(filepath, width = 13, height = 5, dpi = 300, bg = "white")

# Maps and spatial figures
ggsave(filepath, width = 8, height = 7, dpi = 300, bg = "white")
```

## 5. Output Conventions

- Tables → `Results/Tables/` as `.tex` (for LaTeX) and `.csv` (for inspection)
- Figures → `Results/Figures/` as `.pdf` (for LaTeX) and `.png` (for preview)
- Intermediate data → `Data/processed/` as `.rds`

```r
saveRDS(result, file.path("Data/processed", "descriptive_name.rds"))
```

## 6. Common Pitfalls

| Pitfall | Impact | Prevention |
|---------|--------|------------|
| CRS mismatch before `st_join()` | Silent wrong merge | Always `st_crs(a) == st_crs(b)` first |
| `bg = "transparent"` on white paper | Missing background | Use `bg = "white"` for paper figures |
| Hardcoded paths | Breaks on other machines | Use relative paths from repo root |
| Missing `set.seed()` | Non-reproducible results | Always at top of script |
| TWFE with staggered treatment | Negative weights bias | Use Callaway-Sant'Anna or Sun-Abraham |
| Ignoring spatial autocorrelation | Understated SEs | Check Moran's I; consider spatial SEs |

## 7. Line Length & Mathematical Exceptions

**Standard:** Keep lines <= 100 characters.

**Exception: Mathematical Formulas** — lines may exceed 100 chars **if and only if:**

1. Breaking the line would harm readability of the math
2. An inline comment explains the mathematical operation
3. The line is in a numerically intensive section

## 8. Code Quality Checklist

```text
[ ] Packages at top via library()
[ ] set.seed() once at top
[ ] All paths relative to repo root
[ ] Functions documented (Roxygen)
[ ] Figures: white bg, explicit dimensions, 300 dpi
[ ] Tables: exported as .tex and .csv
[ ] RDS: every heavy computed object saved
[ ] CRS verified before any spatial join
[ ] Comments explain WHY not WHAT
```
