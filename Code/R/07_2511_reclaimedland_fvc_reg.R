pacman::p_load(dplyr, ggplot2, tidyverse,fixest,readxl,data.table)

# Load data
setwd("/Users/wangze/Dropbox/Emi/my_project_claude")
cropland <- read.csv("../LandProtection/geodata/Jiangsu_CGCS2000/Jiangsu_grid_cropland_2012_2022.csv")
cropland <- cropland %>%
  mutate(crop_share = cropland_area_m2/250000)
cropland <- cropland %>% pivot_wider(names_from = year, values_from = c(cropland_area_m2, crop_share))
cropland %>% filter(grid_id == 78274)


#--------Define reclaimed land--------
ggplot(cropland, aes(x = crop_share_2012)) + geom_histogram(binwidth = 0.05) +
  labs(x = "Cropland Share in 2022", y = "Count") +
  theme_minimal()
ggplot(cropland, aes(x = crop_share_2012)) +
  stat_ecdf(geom = "step", color = "steelblue", size = 1) +
  labs(
    title = "Empirical Cumulative Distribution of Crop Share",
    x = "Crop Share",
    y = "Cumulative Probability"
  ) +
  theme_minimal(base_size = 14)
cropland %>%
  summarize(
    share_high_crop = mean(crop_share_2012 > 0.95, na.rm = TRUE)
  )
cropland %>%
  summarize(
    share_high_crop = mean(crop_share_2012 < 0.5, na.rm = TRUE)
  )
cropland %>%
  summarize(
    share_high_crop = mean(crop_share_2017 < 0.5 & crop_share_2018 > 0.95, na.rm = TRUE)
  )

results <- data.frame()

for (i in 2012:2020) {
  share <- mean(
    cropland[[paste0("crop_share_", i)]] < 0.6 &
      cropland[[paste0("crop_share_", i + 1)]] > 0.7 &
      cropland[[paste0("crop_share_", i + 2)]] > 0.7,
    na.rm = TRUE
  )
  results <- rbind(results, data.frame(year = i, share_high_crop = share))
}

print(results)

for (i in 2012:2020) {
  cropland <- cropland %>%
    mutate(
      !!paste0("reclaimed_", i) := ifelse(
        !!sym(paste0("crop_share_", i )) < 0.6 &
         !!sym(paste0("crop_share_", i + 1)) > 0.7,
  #        !!sym(paste0("crop_share_", i + 2)) > 0.7,
        1,
        0
      )
    )
}



#---------Import Administrative info-----------
admin <- read.csv("../LandProtection/geodata/Jiangsu_CGCS2000/Jiangsu_grid_with_admin.csv")
admin <- admin %>%
  select(!c(Nm_Prvn,Nm_Cnty,Nm_Prfc,Pinyin))
nm <- read_excel("Data/processed/china_attribute.xlsx")
nm <- nm %>%
  select(Cd_Prvn, Cd_Prfc, Cd_Cnty, Nm_Prvn, Nm_Prfc, Nm_Cnty)
admin <- merge(admin, nm, by = c("Cd_Prvn", "Cd_Prfc", "Cd_Cnty"), all.x = TRUE)
admin <- admin %>% filter(Nm_Prvn == "江苏省")
admin$urban <- ifelse(grepl("区$",admin$Nm_Cnty),1,0)
admin_unique <- admin %>%
  distinct(grid_id, .keep_all = TRUE)
jiangsu <- merge(cropland, admin_unique, by = "grid_id", all.x = TRUE)
urban_share <- jiangsu %>% group_by(Nm_Prfc) %>% summarize(urban_share = mean(urban,na.rm = TRUE)) %>% na.omit()
jiangsu <- merge(jiangsu, urban_share, by = "Nm_Prfc", all.x = TRUE)

names(jiangsu)

write.csv(jiangsu, "../LandProtection/data/Jiangsu/jiangsu_crop_ready.csv", row.names = FALSE)


#---------Event Study: Cropland-----------
jiangsu_long <- jiangsu %>%
  pivot_longer(
    cols = starts_with("crop_share_"),
    names_to = "year",
    names_prefix = "crop_share_",
    values_to = "crop_share"
  ) %>%
  mutate(year = as.numeric(year))

jiangsu_long <- jiangsu_long %>%
  mutate(event_time = year - 2018)

jiangsu_long <- jiangsu_long %>% 
  mutate(event_factor = factor(event_time))

jiangsu_long <- jiangsu_long %>%
  mutate(urban_dum = urban_share > 0.5)

es_model_twfe <- feols(
  crop_share ~ i(event_factor, urban_share, ref = "0") | grid_id + year,
  cluster = ~Nm_Prfc,
  data = filter(jiangsu_long)
)
iplot(
  es_model_twfe,
  main = "Event Study: Effect of Urbanization Intensity on Cropland Share",
  xlab = "Years relative to 2018 (0 year)",
  ylab = "Coefficient × Urban Share",
  ref.line = 0,
  ci.level = 0.95
)

#---------Import FVC data-----------
fvc <- read.csv("../LandProtection/geodata/Jiangsu_CGCS2000/Jiangsu_grid_fvcavg_2012_2022.csv")
fvc <- fvc %>% filter(!is.na(fvc_2012))
names(jiangsu)

dt <- as.data.table(jiangsu)
year_cols <- grep("^reclaimed_", names(dt), value = TRUE)
reclaimed_matrix <- as.matrix(dt[, ..year_cols])
year_labels <- as.numeric(sub("reclaimed_", "", year_cols))

first_year_index <- apply(reclaimed_matrix, 1, function(x) {
  i <- which(x == 1)
  if (length(i) == 0) NA_integer_ else year_labels[min(i)]
})

# === 3. 构建 jiangsu_cohort（多保留两列） ===
jiangsu_cohort <- dt[, .(grid_id, Nm_Prfc, Nm_Cnty, urban, urban_share)]
jiangsu_cohort[, cohort := first_year_index]
jiangsu_cohort <- jiangsu_cohort[cohort >= 2012 & cohort <= 2020]
jiangsu_cohort <- na.omit(jiangsu_cohort)

# === 4. 匹配 fvc，仅保留新增耕地的格子 ===
fvc <- fvc %>%
  semi_join(jiangsu_cohort, by = "grid_id")

# === 5. 宽转长 ===
fvc_long <- fvc %>%
  pivot_longer(
    cols = starts_with("fvc_"),
    names_to = "year",
    names_prefix = "fvc_",
    values_to = "fvc"
  ) %>%
  mutate(year = as.numeric(year)) %>%
  left_join(jiangsu_cohort, by = "grid_id") %>%
  mutate(
    s = year - cohort,
    W = (cohort >= 2018) * urban_share
  ) %>%
  filter(s %in% c(1, 2))  # 仅保留开垦后1、2年

fvc_long <- fvc_long %>% mutate(fallow = fvc < 0.3)

table(fvc_long$s)
table(fvc_long$cohort)


did_model <- feols(
  fallow ~ W | Nm_Prfc + cohort + s,
  cluster = ~Nm_Prfc,
  data = filter(fvc_long)
)

summary(did_model)

did_model <- feols(
  fallow ~ W | Nm_Prfc + cohort + s,
  cluster = ~Nm_Prfc,
  data = filter(fvc_long, s == 2)
)

summary(did_model)

#---------Preparation for visualization-----------
cd_prfc <- admin %>% select(Cd_Prfc, Nm_Prfc,Cd_Cnty,Nm_Cnty) %>% distinct()
years <- 2012:2020
admin_long <- crossing(cd_prfc, cohort = years)
cd_prfc1 <- jiangsu_cohort %>% select(Nm_Cnty,cohort) %>% group_by(Nm_Cnty,cohort) %>% count()
admin_reclaimed <- merge(admin_long, cd_prfc1, by = c("Nm_Cnty","cohort"),  all.x = TRUE) %>% replace_na(list(n = 0))
add_share <- jiangsu %>% select(Nm_Prfc,urban_share) %>% distinct() %>% na.omit()
add_fallow <- fvc_long %>%
  filter(s == 1) %>%
  group_by(Nm_Prfc, cohort) %>%
  summarize(fallow_rate = mean(fallow, na.rm = TRUE), .groups = 'drop')
admin_reclaimed <- merge(admin_reclaimed, add_fallow, by = c("Nm_Prfc","cohort"), all.x = TRUE)
admin_reclaimed <- merge(admin_reclaimed, add_share, by = "Nm_Prfc", all.x = TRUE)
write.csv(admin_reclaimed, "../LandProtection/geodata/Jiangsu_CGCS2000/jiangsu_cohort.csv", row.names = FALSE)



fvc_long <- fvc %>%
  pivot_longer(
    cols = starts_with("fvc_"),
    names_to = "year",
    names_prefix = "fvc_",
    values_to = "fvc"
  ) %>%
  mutate(year = as.numeric(year)) %>%
  left_join(jiangsu_cohort, by = "grid_id") %>%
  mutate(
    s = year - cohort,
    W = (cohort >= 2018)
  ) %>%
  filter(s %in% c(1, 2))  # 仅保留开垦后1、2年

fvc_long <- fvc_long %>% mutate(fallow = fvc < 0.3)

table(fvc_long$s)
table(fvc_long$cohort)


did_model <- feols(
  fallow ~ W | Nm_Prfc + s ,
  cluster = ~Nm_Prfc,
  data = filter(fvc_long)
)
summary(did_model)
