pacman::p_load(dplyr, ggplot2, tidyverse,fixest,readxl,data.table)

# Load data
setwd("/Users/wangze/Dropbox/Emi/Land_Project_wtichcc")
cropland <- read.csv("../LandProtection/data/Jiangsu/jiangsu_crop_ready.csv")
index <- read_excel("Data/processed/jiangsu_land_index/Land_Index.xlsx",sheet = 4)
# Remove spaces, unify names
names(cropland) <- trimws(names(cropland))
names(index) <- trimws(names(index))
index_ratio <- cropland %>% group_by(Nm_Prfc) %>% summarise(crop_hectare_2016 = sum(crop_share_2017*25)) %>% arrange(desc(crop_hectare_2016)) %>% na.omit() %>%
  left_join(index,by=c("Nm_Prfc")) %>% 
  mutate(index_intensity = Designated_Farmland) %>% arrange(desc(index_intensity))
cropland %>% group_by(Nm_Prfc) %>% summarise(crop_hectare_2016 = sum(crop_share_2016*25)) %>% arrange(desc(crop_hectare_2016)) %>% na.omit() %>%
  left_join(index,by=c("Nm_Prfc")) %>% 
  mutate(index_intensity = (Designated_Farmland-crop_hectare_2016)/crop_hectare_2016) %>% arrange(desc(index_intensity))
jiangsu <- cropland %>%
  left_join(index_ratio %>% select(Nm_Prfc,index_intensity),by=c("Nm_Prfc"))


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
jiangsu_cohort <- dt[, .(grid_id, Nm_Prfc, Nm_Cnty, urban_share, index_intensity)]
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
    W = (cohort >= 2018) * index_intensity,
    Wiv = (cohort >= 2018) * urban_share 
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
  data = filter(fvc_long, s == 1)
)

summary(did_model)

jiangsu %>% select(Nm_Cnty,Nm_Prfc) %>% filter(Nm_Prfc == "镇江市") %>%
  distinct()

jiangsu %>% select(urban_share,index_intensity)


ggplot(jiangsu, aes(x = urban_share, y = index_intensity)) +
  geom_point(alpha = 0.5) +                # 散点
  geom_smooth(method = "lm", se = TRUE,   # 回归拟合线
              color = "blue", linetype = "solid") +
  labs(
    x = "Urban Share",
    y = "Land Index Intensity",
    title = "Correlation between Urban Share and Land Index Intensity"
  ) +
  theme_minimal(base_size = 14)


did_model <- feols(
  fallow ~  1| Nm_Prfc + cohort + s | W ~ Wiv,
  cluster = ~Nm_Prfc,
  data = filter(fvc_long, s == 1)
)

summary(did_model)



names(fvc_long)


new_cropland <- fvc_long %>%
  group_by(Nm_Prfc, cohort) %>%
  summarise(
    n_new = n_distinct(grid_id),  # 新增格点数
    .groups = "drop"
  )

ggplot(new_cropland,
       aes(x = cohort, y = n_new, colour = Nm_Prfc, group = Nm_Prfc)) +
  geom_line() +
  geom_point() +
  labs(x = "年份（新增耕地）",
       y = "新增耕地格点数",
       colour = "地级市") +
  theme_minimal() +
  theme(text = element_text(family = "PingFang SC"))

new_cropland <- new_cropland %>% arrange(cohort)


new_grids <- fvc_long %>%
  filter(s == 1) %>% 
  select(grid_id, cohort) %>%
  distinct()

yearly_new <- new_grids %>%
  count(cohort, name = "n_grids") %>%
  mutate(
    area_ha = n_grids * 25,     # 25 hectares per grid
    area_km2 = n_grids * 0.25   # 0.25 km2 per grid
  )

ggplot(yearly_new, aes(x = cohort, y = area_ha)) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  labs(
    x = "Year of Reclamation (cohort)",
    y = "Newly Reclaimed Cropland (hectares)",
    title = "Annual Newly Reclaimed Cropland (500m × 500m grids)"
  ) +
  theme_minimal()


avg_fallow_yearly <- fvc_long %>%
  filter(s == 1) %>%
  group_by(cohort) %>%
  summarise(
    avg_fallow = mean(fallow, na.rm = TRUE),
    .groups = "drop")

    
    

ggplot(avg_fallow_yearly, aes(x = cohort, y = avg_fallow)) +
  geom_line(size = 1.2, color = "#D55E00") +
  geom_point(size = 2.5, color = "#D55E00") +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(
    x = "Year of reclamation (cohort)",
    y = "Average fallow rate",
    title = "Average fallow rate of newly reclaimed cropland"
  ) +
  theme_minimal()

avg_fallow_s12 <- fvc_long %>%
  group_by(cohort, s) %>%
  summarise(avg_fallow = mean(fallow, na.rm = TRUE), .groups = "drop")

ggplot(avg_fallow_s12, aes(x = cohort, y = avg_fallow, color = factor(s))) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  scale_color_manual(values = c("1" = "#0072B2", "2" = "#D55E00"),
                     labels = c("1" = "Year 1", "2" = "Year 2")) +
  scale_y_continuous(labels = scales::percent_format()) +
  labs(
    x = "Cohort",
    y = "Fallow rate",
    color = "Years since reclamation",
    title = "Short-term and medium-term fallow rate after reclamation"
  ) +
  theme_minimal()

urban50 <- fvc_long %>%
  filter(urban_share > 0.5)

avg_fallow_urban50 <- urban50 %>%
  group_by(cohort, s) %>%
  summarise(
    avg_fallow = mean(fallow, na.rm = TRUE),
    .groups = "drop"
  )


ggplot(avg_fallow_urban50,
       aes(x = cohort, y = avg_fallow, color = factor(s), group = s)) +
  geom_line(size = 1.2) +
  geom_point(size = 2.8) +
  scale_color_manual(
    values = c("1" = "#0072B2", "2" = "#D55E00"),
    labels = c("1" = "Year 1", "2" = "Year 2")
  ) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(
    x = "Cohort (year of reclamation)",
    y = "Fallow rate",
    color = "Years since reclamation",
    title = "Fallow rate of newly reclaimed cropland (urban_share > 0.5)"
  ) +
  theme_minimal()



# 1. 按市 × cohort 计算新增耕地开垦后第一年的撂荒率
fallow_prfc <- fvc_long %>%
  filter(s == 2) %>%                  # 开垦后的第 1 年
  group_by(Nm_Prfc, cohort) %>%
  summarise(
    fallow_rate = mean(fallow, na.rm = TRUE),
    .groups = "drop"
  )

# 2. 作图
ggplot(fallow_prfc,
       aes(x = cohort, y = fallow_rate,
           colour = Nm_Prfc, group = Nm_Prfc)) +
  geom_line(size = 1.0) +
  geom_point(size = 2) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_colour_discrete(name = "地级市") +
  labs(
    x = "开垦年份（cohort）",
    y = "撂荒率（开垦后第 1 年）",
    title = "各地级市新增耕地的撂荒率变化（s = 1）"
  ) +
  theme_minimal() +
  theme(text = element_text(family = "PingFang SC"),
        legend.position = "none") +     # ★ 不要 legend（每个 panel 都是单市）
  facet_wrap(~ Nm_Prfc, scales = "free_y")


