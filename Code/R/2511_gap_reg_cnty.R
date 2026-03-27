pacman::p_load(dplyr, ggplot2, tidyverse,fixest,readxl,data.table)

# Load data
setwd("/Users/wangze/Dropbox/Emi/my_project_claude")
cropland <- read.csv("../LandProtection/data/Jiangsu/jiangsu_crop_ready.csv")
index <- read_excel("Data/processed/jiangsu_land_index/Land_Index.xlsx",sheet = 5)
# Remove spaces, unify names
names(cropland) <- trimws(names(cropland))
names(index) <- trimws(names(index))
index_ratio <- cropland %>% group_by(Nm_Cnty) %>% summarise(crop_hectare_2016 = sum(crop_share_2016*25)) %>% arrange(desc(crop_hectare_2016)) %>% na.omit() %>%
  left_join(index,by=c("Nm_Cnty")) %>% 
  mutate(index_intensity = (Designated_Farmland/crop_hectare_2016)) %>% arrange(desc(index_intensity))
cropland %>% group_by(Nm_Cnty) %>% summarise(crop_hectare_2016 = sum(crop_share_2016*25)) %>% arrange(desc(crop_hectare_2016)) %>% na.omit() %>%
  left_join(index,by=c("Nm_Cnty")) %>% 
  mutate(index_intensity = ((crop_hectare_2016-Designated_Farmland)/crop_hectare_2016)) %>% arrange(desc(index_intensity))
jiangsu <- cropland %>%
  left_join(index_ratio %>% select(Nm_Cnty,index_intensity,Nm_Prfc),by=c("Nm_Cnty","Nm_Prfc"))
jiangsu <- jiangsu %>% filter(index_intensity != 0)

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


es_model_twfe <- feols(
  crop_share ~ i(event_factor, index_intensity, ref = "0") | grid_id + year,
  cluster = ~Nm_Cnty,
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
jiangsu_cohort <- dt[, .(grid_id, Nm_Prfc, Nm_Cnty, urban, index_intensity)]
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
    W = (cohort >= 2018) * index_intensity
  ) %>%
  filter(s %in% c(1, 2))  # 仅保留开垦后1、2年

fvc_long <- fvc_long %>% mutate(fallow = fvc < 0.3)

table(fvc_long$s)
table(fvc_long$cohort)


did_model <- feols(
  fallow ~ W | Nm_Cnty + cohort + s,
  cluster = ~Nm_Cnty,
  data = filter(fvc_long)
)

summary(did_model)

did_model <- feols(
  fallow ~ W | Nm_Cnty + cohort + s,
  cluster = ~Nm_Cnty,
  data = filter(fvc_long, s == 2)
)

summary(did_model)

