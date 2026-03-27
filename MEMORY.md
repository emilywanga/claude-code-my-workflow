# Project Memory

Corrections and learned facts that persist across sessions.
When a mistake is corrected, append a `[LEARN:category]` entry below.

---

<!-- Append new entries below. Most recent at bottom. -->

## Workflow Patterns

[LEARN:workflow] Requirements specification phase catches ambiguity before planning → reduces rework 30-50%. Use spec-then-plan for complex/ambiguous tasks (>1 hour or >3 files).

[LEARN:workflow] Spec-then-plan protocol: AskUserQuestion (3-5 questions) → create `quality_reports/specs/YYYY-MM-DD_description.md` with MUST/SHOULD/MAY requirements → declare clarity status (CLEAR/ASSUMED/BLOCKED) → get approval → then draft plan.

[LEARN:workflow] Context survival before compression: (1) Update MEMORY.md with [LEARN] entries, (2) Ensure session log current (last 10 min), (3) Active plan saved to disk, (4) Open questions documented. The pre-compact hook displays checklist.

[LEARN:workflow] Plans, specs, and session logs must live on disk (not just in conversation) to survive compression and session boundaries. Quality reports only at merge time.

## Documentation Standards

[LEARN:documentation] When adding new features, update BOTH README and guide immediately to prevent documentation drift. Stale docs break user trust.

[LEARN:documentation] Always document new templates in README's "What's Included" section with purpose description. Template inventory must be complete and accurate.

[LEARN:documentation] Guide must be generic (framework-oriented) not prescriptive. Provide templates with examples for multiple workflows (LaTeX, R, Python, Jupyter), let users customize. No "thou shalt" rules.

[LEARN:documentation] Date fields in frontmatter and README must reflect latest significant changes. Users check dates to assess currency.

## Design Philosophy

[LEARN:design] Framework-oriented > Prescriptive rules. Constitutional governance works as a TEMPLATE with examples users customize to their domain. Same for requirements specs.

[LEARN:design] Quality standard for guide additions: useful + pedagogically strong + drives usage + leaves great impression + improves upon starting fresh + no redundancy + not slow. All 7 criteria must hold.

[LEARN:design] Generic means working for any academic workflow: pure LaTeX (no Quarto), pure R (no LaTeX), Python/Jupyter, any domain (not just econometrics). Test recommendations across use cases.

## File Organization

[LEARN:files] Specifications go in `quality_reports/specs/YYYY-MM-DD_description.md`, not scattered in root or other directories. Maintains structure.

[LEARN:files] Templates belong in `templates/` directory with descriptive names. Currently have: session-log.md, quality-report.md, exploration-readme.md, archive-readme.md, requirements-spec.md, constitutional-governance.md.

## Constitutional Governance

[LEARN:governance] Constitutional articles distinguish immutable principles (non-negotiable for quality/reproducibility) from flexible user preferences. Keep to 3-7 articles max.

[LEARN:governance] Example articles: Primary Artifact (which file is authoritative), Plan-First Threshold (when to plan), Quality Gate (minimum score), Verification Standard (what must pass), File Organization (where files live).

[LEARN:governance] Amendment process: Ask user if deviating from article is "amending Article X (permanent)" or "overriding for this task (one-time exception)". Preserves institutional memory.

## Skills

[LEARN:skills] `/mixed-language-bridge` skill installed. Parses mixed Chinese+English prompts, replies in English by default, switches to Chinese/Japanese only on explicit request. Source: LandProtection/.claude/skills/mixed-language-bridge/SKILL.md.

## Skill Creation

[LEARN:skills] Effective skill descriptions use trigger phrases users actually say: "check citations", "format results", "validate protocol" → Claude knows when to load skill.

[LEARN:skills] Skills need 3 sections minimum: Instructions (step-by-step), Examples (concrete scenarios), Troubleshooting (common errors) → users can debug independently.

[LEARN:skills] Domain-specific examples beat generic ones: citation checker (psychology), protocol validator (biology), regression formatter (economics) → shows adaptability.

## Memory System

[LEARN:memory] Two-tier memory solves template vs working project tension: MEMORY.md (generic patterns, committed), personal-memory.md (machine-specific, gitignored) → cross-machine sync + local privacy.

[LEARN:memory] Post-merge hooks prompt reflection, don't auto-append → user maintains control while building habit.

## Meta-Governance

[LEARN:meta] Repository dual nature requires explicit governance: what's generic (commit) vs specific (gitignore) → prevents template pollution.

[LEARN:meta] Dogfooding principles must be enforced: plan-first, spec-then-plan, quality gates, session logs → we follow our own guide.

[LEARN:meta] Template development work (building infrastructure, docs) doesn't create session logs in quality_reports/ → those are for user work (slides, analysis), not meta-work. Keeps template clean for users who fork.

---

## Project: When Monitoring Backfires (Land Misallocation in China)

[LEARN:project] Paper: "When Monitoring Backfires: Multi-Tasking Bureaucrats and Land Misallocation in China" — examines how 2017 tightening of cropland protection enforcement creates multitask incentive distortions among Chinese local officials.

[LEARN:project] Identification strategy: Cross-county variation in cropland protection pressure from differential exposure to binding cropland-area constraints WITHIN prefectures (prefecture fixed effects absorb common prefecture-level shocks).

[LEARN:project] Policy shock timing: 2017 reform made cropland-area compliance binding in bureaucratic evaluations while leaving land quality and utilization weakly monitored → multitask response predicted by theory.

[LEARN:project] Key findings: Stricter enforcement → (1) cropland expansion, (2) lower agronomic quality of new land, (3) higher persistent fallow rates. Heterogeneity: stronger for high promotion incentives and high economic growth pressure counties.

[LEARN:project] Data sources: High-resolution satellite data (land cover, vegetation/NDVI/EVI), soil suitability index, administrative boundaries (county/prefecture level), official cropland target registers.

[LEARN:project] Tools: Python (geodata cleaning, satellite processing, geopandas/rasterio), R (econometrics, figures, tables), Stata (cross-checks), LaTeX (manuscript). CRS standard: EPSG:4326 for storage, EPSG:32650/32651 for area calculations.

[LEARN:project] Target journals: AER, QJE, JPub, AEJ:Policy, JDE. Publication-ready standard required for all figures and tables.

[LEARN:project] Folder structure: Paper/ (LaTeX), Code/Python/ + Code/R/ + Code/Stata/, Results/Tables/ + Results/Figures/, Data/processed/ (committed) + Data/raw/ (gitignored). SSOT: Paper/main.tex.

[LEARN:project] Figure standards: Single-column 6.5×4.5in, full-width 13×5in, maps 8×7in; all 300 dpi; bg="white"; palette: navy #1a3a5c, charcoal #3d3d3d, gold #c9a84c, green #2d7a4b, red #b91c1c.

[LEARN:project] Institution: The University of Tokyo.

[LEARN:project] Original project location: /Users/wangze/Dropbox/Emi/LandProtection/ — still exists, is the source of truth for large geodata files. New working project: /Users/wangze/Dropbox/Emi/my_project_claude/.

[LEARN:project] Data architecture: Small processed files (<1MB) in Data/processed/ (committed). Large geodata (CLCD rasters, FVC grids, impervious grids, 49–188MB CSVs) stay in ../LandProtection/geodata/ and ../LandControl/geodata/ — referenced via relative path from R scripts and absolute path from Python notebooks.

[LEARN:project] LaTeX compilation: cd Paper && TEXINPUTS=../Preambles:$TEXINPUTS xelatex -interaction=nonstopmode main.tex. graphicspath = ../Figures/ and ../Results/Figures/. input@path = ./sections/, ./appendix/, ../Results/Tables/. bibliography = ../Bibliography_base.

[LEARN:project] R scripts use setwd("/Users/wangze/Dropbox/Emi/my_project_claude") and reference large data via ../LandProtection/geodata/ or ../LandControl/geodata/. Table outputs → Results/Tables/. Figure outputs → Results/Figures/.

[LEARN:project] Python notebooks in Code/Python/ use absolute paths to /Users/wangze/Dropbox/Emi/LandControl/geodata/ (older project). No path changes needed — absolute paths still valid.

[LEARN:project] Paper sections: main.tex + sections/1_intro through 7_conclusion + appendix/A1_appendix. All are December 2025 drafts (Paper_2512 vintage). Tables in Results/Tables/ (7 .tex files). Figures in Figures/ (37 static files).
