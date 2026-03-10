# =============================================================================
# 10_normalized_pressure.R
#
# Replication of main results (Figure 7, Table 3, Table 4) with Land
# Protection Pressure normalized to SD = 1 (among non-core counties).
# No controls in any specification.
#
# Coefficients are interpreted as: effect of a 1 SD increase in pressure.
#
# Outputs:
#   Results/Figures/res_size_sd1.png      -- Figure 7: event study (cropshare)
#   Results/Tables/res_size_sd1.tex       -- Table: event study coefficients
#   Results/Tables/res_soil_sd1.tex       -- Table 3: soil suitability
#   Results/Tables/res_fallow_sd1.tex     -- Table 4: fallow status
#   Results/Figures/res_fallow_s_sd1.png  -- fallow dynamics by years-since-reclamation
#   Results/Figures/res_fvc_event_sd1.png -- county-level FVC event study
# =============================================================================

pacman::p_load(
  dplyr, ggplot2, tidyverse, fixest, readxl,
  data.table, broom, modelsummary, tibble
)

setwd("/Users/wangze/Dropbox/Emi/my_project_claude")

# =============================================================================
# 1. BUILD LAND PRESSURE INDEX
# =============================================================================

admin <- read.csv("../LandProtection/geodata/Jiangsu_CGCS2000/Jiangsu_grid_with_admin.csv")
admin <- admin %>% select(!c(Nm_Prvn, Nm_Cnty, Nm_Prfc, Pinyin))

nm <- read_excel("Data/processed/china_attribute.xlsx")
nm <- nm %>% select(Cd_Prvn, Cd_Prfc, Cd_Cnty, Nm_Prvn, Nm_Prfc, Nm_Cnty)
admin <- merge(admin, nm, by = c("Cd_Prvn", "Cd_Prfc", "Cd_Cnty"), all.x = TRUE)
admin <- admin %>% filter(Nm_Prvn == "江苏省")
admin_unique <- admin %>% distinct(grid_id, .keep_all = TRUE)

lc <- read_xlsx("../LandProtection/geodata/Jiangsu_CGCS2000/Jiangsu_grid_landcover_share_2012.xlsx")
lc <- lc %>% left_join(admin_unique, by = "grid_id")

reclaimed20 <- read_excel("Data/processed/jiangsu_land_index/Land_Index.xlsx", sheet = "Core Urban")
core <- reclaimed20 %>% select(Nm_Prfc, Nm_Cnty, Core)

lc <- lc %>%
  mutate(available_land = 1 - Water - Impervious) %>%
  mutate(available_land = ifelse(available_land < 0, 0, available_land))

lc_prfc <- lc %>%
  left_join(core, by = c("Nm_Prfc", "Nm_Cnty")) %>%
  group_by(Nm_Prfc) %>%
  summarize(available_land_prfc = sum(available_land * (1 - Core), na.rm = TRUE)) %>%
  na.omit()

lc_cnty <- lc %>%
  left_join(core, by = c("Nm_Prfc", "Nm_Cnty")) %>%
  group_by(Nm_Prfc, Nm_Cnty) %>%
  summarize(available_land_cnty = sum(available_land * (1 - Core), na.rm = TRUE)) %>%
  na.omit()

reclaimed20 <- reclaimed20 %>% mutate(reclaimed_core = Reclaimed_Land_Core * Core)
reclaimed20_prfc <- reclaimed20 %>%
  group_by(Nm_Prfc) %>%
  summarize(reclaimed_core_prfc = sum(reclaimed_core, na.rm = TRUE)) %>%
  na.omit()

index <- admin_unique %>%
  select(Nm_Prfc, Nm_Cnty) %>%
  distinct() %>%
  left_join(lc_prfc, by = "Nm_Prfc") %>%
  left_join(lc_cnty, by = c("Nm_Prfc", "Nm_Cnty")) %>%
  left_join(reclaimed20_prfc, by = "Nm_Prfc") %>%
  left_join(core, by = c("Nm_Prfc", "Nm_Cnty")) %>%
  mutate(
    avail_prfc_ha = available_land_prfc * 25,
    avail_cnty_ha = available_land_cnty * 25
  ) %>%
  group_by(Nm_Prfc) %>%
  mutate(
    LandShare_c  = if_else(avail_prfc_ha > 0, avail_cnty_ha / avail_prfc_ha, NA_real_),
    CityStress_p = reclaimed_core_prfc / avail_prfc_ha,
    Pressure_c   = CityStress_p * LandShare_c * 1000
  ) %>%
  ungroup()

# =============================================================================
# 2. NORMALIZE Pressure_c to SD = 1 (among non-core counties)
# =============================================================================

sd_pressure   <- sd(index$Pressure_c[index$Core < 1], na.rm = TRUE)
mean_pressure <- mean(index$Pressure_c[index$Core < 1], na.rm = TRUE)
cat(sprintf("Pressure_c (non-core):  mean = %.4f,  SD = %.4f\n", mean_pressure, sd_pressure))

index <- index %>%
  mutate(Pressure_c_std = (Pressure_c - mean_pressure) / sd_pressure)

# =============================================================================
# 3. LOAD CROP PANEL AND MERGE
# =============================================================================

jiangsu <- read.csv("../LandProtection/data/Jiangsu/jiangsu_crop_ready.csv")
jiangsu <- left_join(
  jiangsu,
  index %>% select(Nm_Prfc, Nm_Cnty, Core, Pressure_c, Pressure_c_std),
  by = c("Nm_Prfc", "Nm_Cnty")
)

jiangsu_long <- jiangsu %>%
  pivot_longer(
    cols = starts_with("crop_share_"),
    names_to = "year", names_prefix = "crop_share_", values_to = "crop_share"
  ) %>%
  mutate(
    year         = as.numeric(year),
    event_time   = year - 2018,
    event_factor = factor(event_time)
  )

# =============================================================================
# 4. res_size + TABLE (tablenote) -- Event Study: Cropland Share
# =============================================================================
es_size <- feols(
  crop_share ~ i(event_factor, Pressure_c_std, ref = "-1") | grid_id + year,
  cluster = ~Nm_Cnty,
  data    = filter(jiangsu_long, Core < 1)
)
summary(es_size)

# Figure
png("Results/Figures/res_size_sd1.png", width = 1800, height = 1200, res = 180)
iplot(
  es_size,
  main     = "Effect of Land Protection Pressure on Cropland Share (SD = 1)",
  xlab     = "Years relative to 2017",
  ylab     = "Coefficient (1 SD increase in pressure)",
  ref.line = 0
)
dev.off()
cat("Saved: Results/Figures/res_size_sd1.png\n")

# Table
msummary(
  list("Cropland Share" = es_size),
  gof_omit = "IC|Log|Adj|RMSE|Std|F|Within",
  stars    = c(`***` = 0.01, `**` = 0.05, `*` = 0.1),
  notes    = "Two-way fixed effects event study (grid and year FE). Land protection pressure normalized to SD = 1 among non-core counties. Reference period: $k = -1$ (2017). Standard errors clustered at the county level.",
  output   = "Results/Tables/res_size_sd1.tex"
)
cat("Saved: Results/Tables/res_size_sd1.tex\n")

# =============================================================================
# 5. BUILD RECLAMATION-COHORT PANEL
# =============================================================================

for (i in 2013:2021) {
  jiangsu <- jiangsu %>%
    mutate(!!paste0("reclaimed_", i) := ifelse(
      !!sym(paste0("crop_share_", i - 1)) < 0.6 &
        !!sym(paste0("crop_share_", i))   > 0.7 &
        !!sym(paste0("crop_share_", i + 1)) > 0.7,
      1, 0
    ))
}

dt          <- as.data.table(jiangsu)
year_cols   <- grep("^reclaimed_", names(dt), value = TRUE)
recl_matrix <- as.matrix(dt[, ..year_cols])
year_labels <- as.numeric(sub("reclaimed_", "", year_cols))

first_year_index <- apply(recl_matrix, 1, function(x) {
  i <- which(x == 1)
  if (length(i) == 0) NA_integer_ else year_labels[min(i)]
})

jiangsu_cohort <- dt[, .(grid_id, Nm_Prfc, Nm_Cnty, Core, Pressure_c, Pressure_c_std)]
jiangsu_cohort[, cohort := first_year_index]
jiangsu_cohort <- jiangsu_cohort[cohort >= 2012 & cohort <= 2021]
jiangsu_cohort <- na.omit(jiangsu_cohort)

fvc <- read.csv("../LandProtection/geodata/Jiangsu_CGCS2000/Jiangsu_grid_fvcavg_2012_2022.csv")
fvc <- fvc %>% filter(!is.na(fvc_2012)) %>% semi_join(jiangsu_cohort, by = "grid_id")

fvc_long <- fvc %>%
  pivot_longer(
    cols = starts_with("fvc_"),
    names_to = "year", names_prefix = "fvc_", values_to = "fvc"
  ) %>%
  mutate(year = as.numeric(year)) %>%
  left_join(jiangsu_cohort, by = "grid_id") %>%
  mutate(
    s      = year - cohort,
    W      = (cohort >= 2018) * Pressure_c_std,
    fallow = fvc < 0.2
  ) %>%
  filter(s %in% 1:4)

fvc_sub <- fvc_long %>% mutate(s_fac = factor(s))

# =============================================================================
# 6. TABLE 3 -- Soil Suitability
# =============================================================================

soil <- read_xlsx("../LandProtection/geodata/soil_jiangsu/Jiangsu_grid_500m_with_soil.xlsx")
soil <- soil %>% select(grid_id, soil_suit_mean, soil_suit_sd)

soil_reclaimed <- fvc_long %>%
  left_join(soil, by = "grid_id") %>%
  mutate(
    W      = (cohort >= 2018) * Pressure_c_std,
    soil_3 = soil_suit_mean >= 3
  )

soil_cont <- feols(
  soil_suit_mean ~ W | Nm_Cnty + cohort,
  cluster = ~Nm_Cnty,
  data    = filter(soil_reclaimed, Core < 1 & s == 1)
)

soil_dum <- feols(
  soil_3 ~ W | Nm_Cnty + cohort,
  cluster = ~Nm_Cnty,
  data    = filter(soil_reclaimed, Core < 1 & s == 1)
)

cat("\n--- TABLE 3: Soil Suitability ---\n")
summary(soil_cont)
summary(soil_dum)

ctrl_mean_soil <- soil_reclaimed %>%
  filter(Core < 1, s == 1, cohort < 2018) %>%
  summarize(mean_soil3 = mean(soil_3, na.rm = TRUE)) %>%
  pull(mean_soil3)
cat(sprintf("Control mean (soil_3, pre-2018): %.3f\n", ctrl_mean_soil))

check <- "\\checkmark"

msummary(
  list("(1) Soil Index" = soil_cont, "(2) Soil >= 3" = soil_dum),
  coef_map = c("W" = "Land Protection Pressure (SD=1) $\\times$ Post"),
  add_rows = tibble(
    term  = c("County \\& Cohort FE", "N Counties"),
    `(1) Soil Index` = c(check, length(fixef(soil_cont)$Nm_Cnty)),
    `(2) Soil >= 3`  = c(check, length(fixef(soil_dum)$Nm_Cnty))
  ),
  gof_omit = "IC|Log|Adj|RMSE|Std|F|Within",
  stars    = c(`***` = 0.01, `**` = 0.05, `*` = 0.1),
  output   = "Results/Tables/res_soil_sd1.tex"
)
cat("Saved: Results/Tables/res_soil_sd1.tex\n")

# =============================================================================
# 7. TABLE 4 -- Fallow Status
# =============================================================================

res_fallow <- feols(
  fallow ~ W | Nm_Cnty + cohort + s,
  cluster = ~Nm_Cnty,
  data    = filter(fvc_long, Core < 1)
)

cat("\n--- TABLE 4: Fallow Status ---\n")
summary(res_fallow)

ctrl_mean_fallow <- fvc_long %>%
  filter(Core < 1, cohort < 2018) %>%
  summarize(mean_fallow = mean(fallow, na.rm = TRUE)) %>%
  pull(mean_fallow)
cat(sprintf("Control mean (fallow, pre-2018): %.3f\n", ctrl_mean_fallow))

msummary(
  list("(1) Fallow" = res_fallow),
  coef_map = c("W" = "Land Protection Pressure (SD=1) $\\times$ Post"),
  add_rows = tibble(
    term        = c("County \\& Cohort FE", "Year-since-Reclamation FE", "N Counties"),
    `(1) Fallow` = c(check, check, length(fixef(res_fallow)$Nm_Cnty))
  ),
  gof_omit = "IC|Log|Adj|RMSE|Std|F|Within",
  stars    = c(`***` = 0.01, `**` = 0.05, `*` = 0.1),
  output   = "Results/Tables/res_fallow_sd1.tex"
)
cat("Saved: Results/Tables/res_fallow_sd1.tex\n")

# =============================================================================
# 8. FIGURE -- Fallow dynamics by years-since-reclamation
# =============================================================================

mod_fallow_dyn <- feols(
  fallow ~ 0 + W:s_fac | Nm_Cnty + cohort + s_fac,
  cluster = ~Nm_Cnty,
  data    = filter(fvc_sub, Core < 1)
)

results_fallow_dyn <- tidy(mod_fallow_dyn) %>%
  filter(grepl("^W:s_fac", term)) %>%
  mutate(s = as.integer(gsub("W:s_fac", "", term))) %>%
  arrange(s)

p_fallow_dyn <- ggplot(results_fallow_dyn, aes(x = s, y = estimate)) +
  geom_point() +
  geom_errorbar(aes(ymin = estimate - 1.96 * std.error,
                    ymax = estimate + 1.96 * std.error), width = 0.1) +
  geom_hline(yintercept = 0) +
  scale_x_continuous(breaks = 1:4) +
  labs(
    x     = "Years since reclamation",
    y     = "Effect on Pr(fallow)  [1 SD increase in pressure]",
    title = "Fallow Dynamics by Years since Reclamation (Pressure SD = 1)"
  ) +
  theme_classic()

ggsave("Results/Figures/res_fallow_s_sd1.png", p_fallow_dyn, width = 7, height = 5, dpi = 180)
cat("Saved: Results/Figures/res_fallow_s_sd1.png\n")

# =============================================================================
# 9. FIGURE -- County-level FVC event study
# =============================================================================

fvc_all_long <- fvc %>%
  pivot_longer(cols = starts_with("fvc_"),
               names_to = "year", names_prefix = "fvc_", values_to = "fvc") %>%
  mutate(year = as.numeric(year))

fvc_countylevel <- jiangsu_long %>%
  left_join(fvc_all_long, by = c("grid_id", "year")) %>%
  filter(crop_share > 0.6) %>%
  group_by(Nm_Prfc, Nm_Cnty, year) %>%
  summarize(
    fvc            = mean(fvc,            na.rm = TRUE),
    Pressure_c_std = mean(Pressure_c_std, na.rm = TRUE),
    Core           = mean(Core,           na.rm = TRUE),
    .groups        = "drop"
  ) %>%
  na.omit()

es_fvc <- feols(
  fvc ~ i(year, Pressure_c_std, ref = "2017") | Nm_Cnty + year,
  cluster = ~Nm_Cnty,
  data    = filter(fvc_countylevel, Core < 1)
)
summary(es_fvc)

png("Results/Figures/res_fvc_event_sd1.png", width = 1800, height = 1200, res = 180)
iplot(
  es_fvc,
  main     = "Effect of Land Protection Pressure on County-Level Cropland FVC (SD = 1)",
  xlab     = "Year",
  ylab     = "Coefficient (1 SD increase in pressure)",
  ref.line = 0
)
dev.off()
cat("Saved: Results/Figures/res_fvc_event_sd1.png\n")

# =============================================================================
# 10. SUMMARY
# =============================================================================

cat("\n\n========================================================\n")
cat("SUMMARY: Coefficients for 1 SD increase in Pressure_c\n")
cat("========================================================\n")
cat(sprintf("  SD of Pressure_c (non-core):  %.4f\n\n", sd_pressure))

cat("Table 3 -- Soil suitability (s=1, non-core):\n")
cat(sprintf("  Continuous:  coef = %.4f,  se = %.4f\n", coef(soil_cont)["W"], se(soil_cont)["W"]))
cat(sprintf("  Binary(>=3): coef = %.4f,  se = %.4f\n", coef(soil_dum)["W"],  se(soil_dum)["W"]))
cat(sprintf("  Control mean (soil_3, pre-2018): %.3f\n\n", ctrl_mean_soil))

cat("Table 4 -- Fallow (non-core):\n")
cat(sprintf("  coef = %.4f,  se = %.4f\n", coef(res_fallow)["W"], se(res_fallow)["W"]))
cat(sprintf("  Control mean (fallow, pre-2018): %.3f\n", ctrl_mean_fallow))
cat("========================================================\n")