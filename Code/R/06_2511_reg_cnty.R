pacman::p_load(dplyr, ggplot2, tidyverse,fixest,readxl,data.table,skimr,broom,purrr,writexl,modelsummary,tibble,kableExtra)


setwd("/Users/wangze/Dropbox/Emi/Land_Project_wtichcc")
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

names(admin_unique)
lc <- read_xlsx("../LandProtection/geodata/Jiangsu_CGCS2000/Jiangsu_grid_landcover_share_2012.xlsx")
lc <- lc %>%
  left_join(admin_unique,by=c("grid_id"))

reclaimed20 <- read_excel("Data/processed/jiangsu_land_index/Land_Index.xlsx",sheet = "Core Urban")
core <- reclaimed20 %>% select(Nm_Prfc,Nm_Cnty,Core)
# lc <- lc %>% mutate(available_land = 1) %>% mutate(available_land = ifelse(available_land<0,0,available_land))
lc <- lc %>% mutate(available_land = 1 - Water - Impervious) %>% mutate(available_land = ifelse(available_land<0,0,available_land))
lc_prfc <- lc %>% left_join(core,by=c("Nm_Prfc","Nm_Cnty")) %>% 
  group_by(Nm_Prfc) %>% summarize(available_land_prfc = sum(available_land*(1-Core),na.rm=TRUE)) %>% na.omit()
lc_cnty <- lc %>% left_join(core,by=c("Nm_Prfc","Nm_Cnty")) %>% group_by(Nm_Prfc,Nm_Cnty) %>% summarize(available_land_cnty= sum(available_land*(1-Core),na.rm=TRUE)) %>% na.omit()
reclaimed20 <- reclaimed20 %>% mutate(reclaimed_core = Reclaimed_Land_Core*Core)
reclaimed20_prfc <- reclaimed20 %>% group_by(Nm_Prfc) %>% summarize(reclaimed_core_prfc = sum(reclaimed_core,na.rm=TRUE)) %>% na.omit()
index <- admin_unique %>% select(Nm_Prfc,Nm_Cnty) %>% distinct() %>% 
  left_join(lc_prfc,by=c("Nm_Prfc")) %>% 
  left_join(lc_cnty,by=c("Nm_Prfc","Nm_Cnty")) %>% 
  left_join(reclaimed20_prfc,by=c("Nm_Prfc")) %>%
  left_join(core,by=c("Nm_Prfc","Nm_Cnty")) 

index <- index %>%
  # ① 把 available_land 统一成 ha
  mutate(
    avail_prfc_ha = available_land_prfc * 25,
    avail_cnty_ha = available_land_cnty * 25
  ) %>%
  group_by(Nm_Prfc) %>%
  # ② 在市级内构造 LandShare 和 CityStress
  mutate(
    # 县级在市内的 available land share
    LandShare_c = if_else(
      avail_prfc_ha > 0,
      avail_cnty_ha / avail_prfc_ha,
      NA_real_
    ),
    # 市级“stress per unit of available land”
    CityStress_p = reclaimed_core_prfc / avail_prfc_ha,
    # 最终的 Pressure 指标
    Pressure_c = CityStress_p * LandShare_c * 1000
  ) %>%
  ungroup()



#以下是主要按中心城区进行划分的
#write_xlsx(index,"Data/processed/jiangsu_land_index/Land_Pressure_Index_List.xlsx")

##---------------Event Study: Cropland Expansion----------------
# Load data
jiangsu <- read.csv("../LandProtection/data/Jiangsu/jiangsu_crop_ready.csv")
jiangsu <- left_join(jiangsu,index %>% select(Nm_Prfc,Nm_Cnty,Core, Pressure_c),by=c("Nm_Prfc","Nm_Cnty"))
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


med_noncore <- jiangsu_long %>% 
  filter(Core < 1) %>% 
  summarize(med = median(Pressure_c, na.rm = TRUE)) %>% 
  pull(med)


jiangsu_long <- jiangsu_long %>%
  mutate(
    Pressure_dum = Pressure_c > med_noncore
  )

jiangsu_long %>% skim(Pressure_c)
es_model_twfe <- feols(
  crop_share ~ i(event_factor, Pressure_c, ref = "-1") | grid_id + year,
  cluster = ~Nm_Cnty,
  data = filter(jiangsu_long,Core < 1)
)

##############res_size################
iplot(
  es_model_twfe,
  main = "Effect of Land Protection Pressure on Grid-level Cropland Share",
  xlab = "Years relative to 2017",
  ylab = "Coefficients",
  ref.line = 0
)
summary(es_model_twfe)
#write.csv(jiangsu_long,"Data/processed/jiangsu_land_index/jiangsu_long.csv",row.names=FALSE)

#--------Define reclaimed land--------
for (i in 2013:2021) {
  jiangsu <- jiangsu %>%
    mutate(
      !!paste0("reclaimed_", i) := ifelse(
        !!sym(paste0("crop_share_", i - 1)) < 0.6 &
          !!sym(paste0("crop_share_", i )) > 0.7 &
                !!sym(paste0("crop_share_", i + 1)) > 0.7,
        1,
        0
      )
    )
}

# for (i in 2013:2021) {
#   jiangsu <- jiangsu %>%
#     mutate(
#       !!paste0("reclaimed_", i) := ifelse(
#         !!sym(paste0("crop_share_", i)) - !!sym(paste0("crop_share_", i - 1)) > 0.2,
#         1,
#         0
#       )
#     )
# }

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
jiangsu_cohort <- dt[, .(grid_id, Nm_Prfc, Nm_Cnty, Core, Pressure_c)]
jiangsu_cohort[, cohort := first_year_index]
jiangsu_cohort <- jiangsu_cohort[cohort >= 2012 & cohort <= 2021]
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
    W = (cohort >= 2018) * (Pressure_c)
  ) %>%
  filter(s %in% c(1, 2, 3, 4))  # 仅保留开垦后1、2年

fvc_long <- fvc_long %>% mutate(fallow = fvc < 0.2)

table(fvc_long$s)
table(fvc_long$cohort)



res_fallow <- feols(
  fallow ~ W | Nm_Cnty + cohort + s,
  cluster = ~Nm_Cnty,
  data = filter(fvc_long, Core < 1)
)

summary(res_fallow)

control_mean <- fvc_long %>%
  filter(Core < 1) %>%
  summarize(mean_fallow = mean(fallow, na.rm = TRUE))

control_mean

res_fvc <- feols(
  fvc ~ W | Nm_Cnty + cohort + s,
  cluster = ~Nm_Cnty,
  data = filter(fvc_long, Core < 1)
)

summary(res_fvc)

fvc_sub <- fvc_long %>%
  filter(Core < 1, s %in% 1:4) %>%
  mutate(s_fac = factor(s))       # 把 s 变成 factor，方便交互

# 一个回归一次性估出 beta_s
mod_all <- feols(
  fallow ~ 0 + W:s_fac | Nm_Cnty + cohort + s_fac,   # 0 + 只保留 W×s 的系数
  cluster = ~Nm_Cnty,
  data = fvc_sub
)

results_df <- tidy(mod_all) %>%
  # term 形如 "W:s_fac1" "W:s_fac2" ...
  filter(grepl("^W:s_fac", term)) %>%
  mutate(
    s = as.integer(gsub("W:s_fac", "", term))   # 从 term 里提取 s=1..4
  ) %>%
  arrange(s)


#####################Figure:res_fallow_s##################
ggplot(results_df, aes(x = s, y = estimate)) +
  geom_point() +
  geom_errorbar(aes(ymin = estimate - 1.96 * std.error,
                    ymax = estimate + 1.96 * std.error),
                width = 0.1) +
  geom_hline(yintercept = 0) +
  scale_x_continuous(breaks = 1:4) +
  labs(
    x = "Years since reclamation",
    y = "",
    title = "Effect of Land Pressure × post policy by years since reclamation"
  ) +
  theme_classic()



##----------------- Plot mean FVC by s ----------------

#############Figure des_fvctrend##################
fvc_long_s <- fvc %>%
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
    W = (cohort >= 2018) * (Pressure_c)
  ) 

fvc_by_s <- fvc_long_s %>%
  filter(Core < 1,                      
         s >= 1) %>%          
  group_by(s) %>%
  summarise(
    mean_fvc = mean(fvc, na.rm = TRUE),
    sd_fvc   = sd(fvc,   na.rm = TRUE),
    n        = n(),
    se_fvc   = sd_fvc / sqrt(n),
    ci_low   = mean_fvc - 1.96 * se_fvc,
    ci_high  = mean_fvc + 1.96 * se_fvc,
    .groups  = "drop"
  )

##############Figure: Motivating_reclaimed################
ggplot(fvc_by_s, aes(x = s, y = mean_fvc)) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  geom_errorbar(aes(ymin = ci_low, ymax = ci_high),
                width = 0.1) +
  scale_x_continuous(breaks = 1:10) +
  labs(
    title = "Mean FVC  of Newly Reclaimed Land in Jiangsu Province",
    x     = "Years since reclamation",
    y     = "Mean FVC"
  ) +
  theme_minimal(base_size = 14) +
  theme_classic()

# 以县层 Pressure_c 中位数划分高压 / 低压
fvc_by_s_hp <- fvc_long %>%
  filter(Core < 1, s >= 1, s <= 4) %>%
  mutate(HighPressure = Pressure_c > mean(Pressure_c, na.rm = TRUE)) %>%
  group_by(HighPressure, s) %>%
  summarise(
    mean_fvc = mean(fvc, na.rm = TRUE),
    sd_fvc   = sd(fvc,   na.rm = TRUE),
    n        = n(),
    se_fvc   = sd_fvc / sqrt(n),
    ci_low   = mean_fvc - 1.96 * se_fvc,
    ci_high  = mean_fvc + 1.96 * se_fvc,
    .groups  = "drop"
  )

# 以县层 Pressure_c 中位数划分高压 / 低压
fvc_by_s_hp <- fvc_long %>%
  filter(Core < 1, s >= 1, s <= 4) %>%
  mutate(HighPressure = Pressure_c > median(Pressure_c, na.rm = TRUE)) %>%
  group_by(HighPressure, s) %>%
  summarise(
    mean_fvc = mean(fvc, na.rm = TRUE),
    sd_fvc   = sd(fvc,   na.rm = TRUE),
    n        = n(),
    se_fvc   = sd_fvc / sqrt(n),
    ci_low   = mean_fvc - 1.96 * se_fvc,
    ci_high  = mean_fvc + 1.96 * se_fvc,
    .groups  = "drop"
  )

fvc_by_s_hp <- fvc_long %>%
  filter(Core < 1, s >= 1, s <= 4) %>%
  mutate(HighPressure = Pressure_c > median(Pressure_c, na.rm = TRUE)) %>%
  group_by(HighPressure, s) %>%
  summarise(
    mean_fvc = mean(fvc, na.rm = TRUE),
    sd_fvc   = sd(fvc,   na.rm = TRUE),
    n        = n(),
    se_fvc   = sd_fvc / sqrt(n),
    ci_low   = mean_fvc - 1.96 * se_fvc,
    ci_high  = mean_fvc + 1.96 * se_fvc,
    .groups  = "drop"
  )

ggplot(fvc_by_s_hp,
       aes(x = s, y = mean_fvc,
           group = HighPressure,
           linetype = HighPressure)) +
  geom_line() +
  geom_point(size = 2) +
  geom_errorbar(aes(ymin = ci_low, ymax = ci_high),
                width = 0.1) +
  scale_x_continuous(breaks = 1:4) +
  scale_linetype_manual(
    name   = "Land pressure",
    values = c("FALSE" = "solid", "TRUE" = "dashed"),
    labels = c("Low pressure", "High pressure")
  ) +
  labs(
    title = "Mean FVC of Newly Reclaimed Land by Years Since Reclamation",
    x     = "Years since reclamation (s)",
    y     = "Mean FVC on newly reclaimed land"
  ) +
  theme_minimal(base_size = 14)


fvc_data <- fvc_long %>%
  filter(Core < 1, s %in% 1:4) %>%
  mutate(
    HighPressure = ifelse(Pressure_c > med_noncore,
                          "High pressure", "Low pressure"),
    PostPolicy   = ifelse(cohort >= 2018, "Post-2018", "Pre-2018")
  )

##############Figure des_did:Descriptive Anaysis###############
fvc_grouped <- fvc_data %>%
  group_by(HighPressure, PostPolicy, s) %>%
  summarise(
    mean_fvc = mean(fvc, na.rm = TRUE),
    sd_fvc   = sd(fvc, na.rm = TRUE),
    n        = n(),
    se_fvc   = sd_fvc / sqrt(n),
    ci_low   = mean_fvc - 1.96 * se_fvc,
    ci_high  = mean_fvc + 1.96 * se_fvc,
    .groups  = "drop"
  )

fvc_long %>% filter(s == 1 & cohort >= 2018 & Pressure_c < med_noncore) %>% summarise(mean(fvc,na.rm=TRUE),sd(fvc,na.rm=TRUE),n())

################Figure:Motivating_reclaimed_group##################
ggplot(filter(fvc_grouped,s %in% 1:3),
       aes(x = s, y = mean_fvc,
           color = PostPolicy,
           linetype = HighPressure,
           group = interaction(PostPolicy, HighPressure))) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  geom_errorbar(aes(ymin = ci_low, ymax = ci_high),
                width = 0.12) +
  scale_x_continuous(breaks = 1:4) +
  scale_color_manual(
    values = c("Pre-2018" = "black", "Post-2018" = "blue"),
    name   = "Policy period"
  ) +
  scale_linetype_manual(
    values = c("Low pressure" = "dashed", "High pressure" = "solid"),
    name   = "County Type"
  ) +
  labs(
    title = "Mean FVC of Newly Reclaimed Land by Land Pressure and Policy Period",
    x = "Years since reclamation",
    y = "Mean FVC"
  ) +
  theme_minimal(base_size = 14) +
  theme_classic()

#########-------------------With Controls-----------------##############
stats <- read_excel("Data/processed/stats.xlsx")
names(stats)
stats <- stats %>%
  rename(
    Nm_Cnty  = `地区名称`,
    Nm_Prfc  = `所属城市`,
    Pop_2010 = `户籍人口数(万人)`,
    gdp_2010 = `地区生产总值(万元)`,
    size     = `行政区域土地面积(平方公里)`,
    govbud_10 = `地方财政一般预算收入(万元)`
  ) %>% 
  select(Nm_Cnty, Nm_Prfc, Pop_2010, gdp_2010, size, govbud_10)


jiangsu_long <- jiangsu_long %>%
  left_join(stats, by = c("Nm_Cnty", "Nm_Prfc"))

jiangsu_long <- jiangsu_long %>%
  mutate(
    t = year - 2018,
    Pop_t   = Pop_2010 * t,
    GDP_t   = gdp_2010 * t,
    size_t = size * t,
    govbud_10_t = govbud_10 * t,
  )

  
lc_cov <- c("Cropland","Forest","Shrub","Grassland","Water","Wetland","Impervious") 
stats_cov <- c("Pop_2010","gdp_2010","size","govbud_10")
control_vars <- c("Pop_t","GDP_t","size_t","govbud_10_t")

fml_es <- as.formula(
  paste0(
    "crop_share ~ i(event_factor, Pressure_c, ref='-1') + ",
    paste(control_vars, collapse=" + "),
    " | grid_id + year"
  )
)

es_model_twfe <- feols(
  fml_es,
  cluster = ~Nm_Cnty,
  data = filter(jiangsu_long,Core < 1)
)
iplot(
  es_model_twfe,
  main = "Event Study: Effect of Land Pressure on Cropland Share",
  xlab = "Years relative to 2017 (-1 year)",
  ylab = "Coefficient × Urban Share",
  ref.line = 0
)


jiangsu_long <- jiangsu_long %>% mutate(Post2018 = ifelse(year>=2018,1,0))
jiangsu_long <- jiangsu_long %>% left_join(
  index %>% select(Nm_Prfc,reclaimed_core_prfc) %>% distinct(), by = "Nm_Prfc"
)

jiangsu_long <- jiangsu_long %>%
  mutate(
    reclaimed_core_prfc_t = reclaimed_core_prfc * t
  )

fml_es <- as.formula(
  paste0(
    "crop_share ~ i(event_factor, Pressure_c, ref='0') + i(Nm_Prfc,year) + ",
    paste(control_vars, collapse=" + "),
    " | grid_id + year"
  )
)

fml_es <- as.formula(
  paste0(
    "crop_share ~ i(event_factor, Pressure_c, ref='-1') + reclaimed_core_prfc_t +",
    paste(control_vars, collapse=" + "),
    " | grid_id + year"
  )
)



es_model_twfe <- feols(
  fml_es,
  cluster = ~Nm_Cnty,
  data = filter(jiangsu_long,Core < 1)
)

iplot(
  es_model_twfe,
  main = "Event Study: Effect of Land Pressure on Cropland Share",
  xlab = "Years relative to 2017 (-1 year)",
  ylab = "Coefficient × Urban Share",
  ref.line = 0)


###########FVC with control###############
fvc_subc <- fvc_sub %>%
  left_join(stats, by = c("Nm_Cnty", "Nm_Prfc")) %>%
  left_join(
    index %>% select(Nm_Prfc,reclaimed_core_prfc) %>% distinct(), by = "Nm_Prfc"
  ) %>%
  mutate(
    t = year - 2018,
    Pop_t   = Pop_2010 * t,
    GDP_t   = gdp_2010 * t,
    size_t = size * t,
    govbud_10_t = govbud_10 * t,
    reclaimed_core_prfc_t = reclaimed_core_prfc * t
  )


jiangsu_long %>% filter(Pressure_c > 140) %>% select(Nm_Prfc,Nm_Cnty)

control_vars <- c("Pop_t","GDP_t","size_t","govbud_10_t")
# control_vars <- c("Pop_t","GDP_t","size_t","govbud_10_t","reclaimed_core_prfc_t")

fml_es <- as.formula(
  paste0(
    "fallow ~ W + ",
    paste(control_vars, collapse=" + "),
    " | Nm_Cnty + cohort + s"
  )
)

res_fallow_c <- feols(
  fml_es, 
  cluster = ~Nm_Cnty,
  data = filter(fvc_subc, Core < 1)
)
summary(res_fallow_c)

fml_es <- as.formula(
  paste0(
    "fvc~ 0 + W + ",
    paste(control_vars, collapse=" + "),
    " | Nm_Cnty + cohort + s"
  )
)

res_fvc_c <- feols(
  fml_es, 
  cluster = ~Nm_Cnty,
  data = filter(fvc_subc, Core < 1)
)
summary(res_fvc_c)


fml_es <- as.formula(
  paste0(
    "fallow ~ 0 + W:s_fac + ",
    paste(control_vars, collapse=" + "),
    " | Nm_Cnty + cohort + s_fac"
  )
)

##以下是带Prefecture level的trend的控制

# fml_es <- as.formula(
#   paste0(
#     "fallow ~ 0 + W:s_fac + i(Nm_Prfc,year) + ",
#     paste(control_vars, collapse=" + "),
#     " | Nm_Cnty + cohort + s_fac"
#   )
# )

fvc_subc <- fvc_subc %>% mutate(fallow = fvc < 0.2,W = (cohort >= 2018) * (Pressure_c))

mod_all <- feols(
  fml_es, 
  cluster = ~Nm_Cnty,
  data = fvc_subc
)


results_df <- tidy(mod_all) %>%
  # term 形如 "W:s_fac1" "W:s_fac2" ...
  filter(grepl("^W:s_fac", term)) %>%
  mutate(
    s = as.integer(gsub("W:s_fac", "", term)) 
  ) %>%
  arrange(s)

ggplot(results_df, aes(x = s, y = estimate)) +
  geom_point() +
  geom_errorbar(aes(ymin = estimate - 1.96 * std.error,
                    ymax = estimate + 1.96 * std.error),
                width = 0.1) +
  geom_hline(yintercept = 0) +
  scale_x_continuous(breaks = 1:4) +
  labs(
    x = "Years since reclamation (s)",
    y = "Effect of W on fallow",
    title = "Effect of land pressure × post policy by years since reclamation"
  ) +
  theme_minimal()
                     

ggplot(filter(index, Pressure_c > 0), aes(x = Pressure_c)) +
  geom_density()

##-------------------Event Study: FVC (Parallel Trend Test)-----------------------

fvc_all_long <- fvc %>%
  pivot_longer(
    cols = starts_with("fvc_"),
    names_to = "year",
    names_prefix = "fvc_",
    values_to = "fvc"
  ) %>%
  mutate(year = as.numeric(year))
jiangsu_long <- jiangsu_long %>%
  left_join(fvc_all_long, by = c("grid_id","year"))

fvc_countylevel <- jiangsu_long %>% filter(crop_share>0.6) %>% group_by(Nm_Prfc,Nm_Cnty,year) %>%
  summarize(fvc = mean(fvc,na.rm=TRUE),Pressure_c = mean(Pressure_c,na.rm=TRUE),Core = mean(Core,na.rm=TRUE)) %>%
  ungroup() %>% na.omit()


fvc_countylevel <- fvc_countylevel %>% mutate(Pressure_dum = Pressure_c )
fml_es <- as.formula(
    "fvc ~ i(year, Pressure_c, ref='2017') | Nm_Cnty + year"
  )

es_model_twfe <- feols(
  fml_es,
  cluster = ~Nm_Cnty,
  data = filter(fvc_countylevel,Core < 1))


##########Figure:res_fvc_event################
iplot(
  es_model_twfe,
  main = "",
  xlab = "Years",
  ylab = "Coefficient",
  ref.line = 0
)
summary(es_model_twfe)

##-------------------DEM-----------------------
###没什么影响，我觉得这是因为，江苏的地形起伏并不明显，如下图所示
dem <- read_xlsx("../LandProtection/geodata/Jiangsu_CGCS2000/Jiangsu_grid_500m_ID_with_dem.xlsx")
dem_reclaimed <- fvc_long %>%
  left_join(dem, by = "grid_id")
names(dem_reclaimed)
dem_reclaimed <- dem_reclaimed %>%
  mutate(
    W = (cohort >= 2018) * (Pressure_c)
  )
did_model <- feols(
  tri_mean ~ W | Nm_Cnty + cohort + s,
  cluster = ~Nm_Cnty,
  data = filter(dem_reclaimed, Core < 1)
)

summary(did_model)

ggplot(dem_reclaimed, aes(x = tri_mean)) +
  geom_density() +
  labs(
    title = "Distribution of Terrain Ruggedness Index (TRI)",
    x     = "TRI",
    y     = "Density"
  ) +
  theme_minimal(base_size = 14)

##---------------------Soil Perfect!!!!------------------------
soil <- read_xlsx("../LandProtection/geodata/soil_jiangsu/Jiangsu_grid_500m_with_soil.xlsx")
soil <- soil %>% select(grid_id,soil_suit_mean,soil_suit_sd) 
soil %>% skim(soil_suit_mean)
names(soil)
soil_reclaimed <- fvc_long %>%
  left_join(soil, by = "grid_id")

soil_reclaimed <- soil_reclaimed %>%
  mutate(
    W = (cohort >= 2018) * (Pressure_c),
    soil_5 = soil_suit_mean == 5,
    soil_3 = soil_suit_mean >= 3
  )
soil_cont <- feols(
  soil_suit_mean ~ W | Nm_Cnty + cohort,
  cluster = ~Nm_Cnty,
  data = filter(soil_reclaimed, Core < 1 & s == 1)
)

summary(soil_cont)

control_mean <- soil_reclaimed %>%
  filter(Core < 1, s == 1, W == 0) %>%
  summarize(mean_soil = mean(soil_3, na.rm = TRUE))

control_mean

did_model <- feols(
  soil_5 ~ W | Nm_Cnty + cohort ,
  cluster = ~Nm_Cnty,
  data = filter(soil_reclaimed, Core < 1 & s == 1)
)

summary(did_model)

soil_dum <- feols(
  soil_3 ~ W | Nm_Cnty + cohort,
  cluster = ~Nm_Cnty,
  data = filter(soil_reclaimed, Core < 1 & s == 1)
)

summary(soil_dum)


##With control

soil_reclaimed_c <- soil_reclaimed %>%
  left_join(stats, by = c("Nm_Cnty", "Nm_Prfc")) %>%
  left_join(
    index %>% select(Nm_Prfc,reclaimed_core_prfc) %>% distinct(), by = "Nm_Prfc"
  ) %>%
  mutate(
    t = 2018 - year,
    Pop_t   = Pop_2010 * t,
    GDP_t   = gdp_2010 * t,
    size_t = size * t,
    govbud_10_t = govbud_10 * t
  )
names(soil_reclaimed_c)

fml_es <- as.formula(
  paste0(
    "soil_suit_mean ~  W +",
    paste(control_vars, collapse=" + "),
    " | Nm_Cnty + cohort"
  )
)


soil_cont_c <- feols(
  fml_es,
  cluster = ~Nm_Cnty,
  data = filter(soil_reclaimed_c, Core < 1 & s == 1)
)

summary(soil_cont_c)

fml_es <- as.formula(
  paste0(
    "soil_3 ~  W +",
    paste(control_vars, collapse=" + "),
    " | Nm_Cnty + cohort"
  )
)

soil_dum_c <- feols(
  fml_es,
  cluster = ~Nm_Cnty,
  data = filter(soil_reclaimed_c, Core < 1 & s == 1)
)

summary(soil_dum_c)

################-----Table: Soil Quality Regression Results (res_soil.tex)-------##########

# ---- 1. 把四个模型按你说的“朴实无华方式”存入 list ----
res <- list()
res[["(1)"]] <- soil_cont
res[["(2)"]] <- soil_cont_c
res[["(3)"]] <- soil_dum
res[["(4)"]] <- soil_dum_c

# ---- 2. Coef rename ----
coef_map_soil <- c("W" = "Land Protection Pressure × Post")

# ---- 3. 添加 County & Cohort FE 行 ----
check <- "✓"   # 直接用 Unicode 勾号，最省心

n_cty <- c(
  "(1)" = length(fixef(soil_cont)$Nm_Cnty),
  "(2)" = length(fixef(soil_cont_c)$Nm_Cnty),
  "(3)" = length(fixef(soil_dum)$Nm_Cnty),
  "(4)" = length(fixef(soil_dum_c)$Nm_Cnty)
)

extra_rows <- tibble(
  term = c("County Controls", "County & Cohort FE", "Number of Counties"),
  `(1)` = c("",      check,   n_cty["(1)"]),
  `(2)` = c(check,   check,   n_cty["(2)"]),
  `(3)` = c("",      check,   n_cty["(3)"]),
  `(4)` = c(check,   check,   n_cty["(4)"])
)

# ---- 4. 输出 LaTeX ----
 msummary(
  res,
  coef_map = coef_map_soil,
  add_rows = extra_rows,
  gof_omit = "IC|Log|Adj|RMSE|Std|F|Within",
  stars = c(`***` = 0.01, `**` = 0.05, `*` = 0.1),
  output = "latex"
)

###################---------Table: Fallow Rate Regression Results (res_fallow.tex)---------##############
# ---- 1. 把四个模型按你说的“朴实无华方式”存入 list ----
res <- list()
res[["(1)"]] <- res_fallow
res[["(2)"]] <- res_fallow_c


# ---- 2. Coef rename ----
coef_map_soil <- c("W" = "Land Protection Pressure × Post")

# ---- 3. 添加 County & Cohort FE 行 ----
check <- "✓"   # 直接用 Unicode 勾号，最省心

n_cty <- c(
  "(1)" = length(fixef(res_fallow)$Nm_Cnty),
  "(2)" = length(fixef(res_fallow_c)$Nm_Cnty)
)

extra_rows <- tibble(
  term = c("County Controls", "County & Cohort FE", "Year since Reclamation FE", "Number of Counties"),
  `(1)` = c("",      check,  check, n_cty["(1)"]),
  `(2)` = c(check,   check,  check, n_cty["(2)"])
)

# ---- 4. 输出 LaTeX ----
msummary(
  res,
  coef_map = coef_map_soil,
  add_rows = extra_rows,
  gof_omit = "IC|Log|Adj|RMSE|Std|F|Within",
  stars = c(`***` = 0.01, `**` = 0.05, `*` = 0.1),
  output = "latex"
)
soil_reclaimed %>% filter(Core < 1) %>% count(Nm_Cnty)
print(soil_reclaimed %>% count(Nm_Cnty,cohort), n = 275)

#############-----------ClCD Cropland vs Reported Cropland---------------
reported_land <- read_excel("Data/processed/jiangsu_land_index/Land_Index.xlsx",sheet = "reported")
med_pressure_noncore <- index %>% filter(Core < 1) %>% group_by(Nm_Prfc) %>%
  summarize(med = median(Pressure_c, na.rm=TRUE)) 
med_pressure_noncore
clcd_land <- jiangsu %>% group_by(Nm_Prfc) %>%
  summarize(clcd_ladn = sum(crop_share_2014*25,na.rm=TRUE)) %>% ungroup() 
land_compare <- reported_land %>% 
  left_join(clcd_land,by=c("Nm_Prfc")) %>%
  mutate(ratio = Reported_Farmland/clcd_ladn) %>%
  left_join(med_pressure_noncore,by=c("Nm_Prfc"))
names(land_compare)
ggplot(land_compare, aes(x = med, y = ratio)) +
  geom_point() +
  geom_smooth(method = "lm", se = TRUE, color = "blue") +
  labs(
    title = "Ratio of Reported Farmland to CLCD-derived Farmland vs Land Pressure",
    x     = "Land Pressure",
    y     = "Ratio of Reported Farmland to CLCD-derived Farmland"
  ) +
  theme_minimal(base_size = 14)
land_compare %>% arrange(ratio)

write.csv(fvc_long,"Data/processed/jiangsu_land_index/fvc_long.xlsx")


jiangsu_long <- jiangsu_long %>% mutate(post = ifelse(year>=2018,1,0), Pressure_dum = ifelse(Pressure_c>med_noncore,1,0))
res_crop <- feols(
  crop_share ~ Pressure_c:post | grid_id + year,
  cluster = ~Nm_Cnty,
  data = filter(jiangsu_long, Core < 1)
)
summary(res_crop)
summary(soil_dum)

names(jiangsu)
# === County-level summary statistics ===
index <- jiangsu %>%
  group_by(Nm_Prfc, Nm_Cnty) %>%
  summarize(
    cropland_area = sum(crop_share_2021 * 25, na.rm = TRUE),
    available_land_cnty = mean(available_land_cnty, na.rm = TRUE),
    available_land_prfc = mean(available_land_prfc, na.rm = TRUE),
    Core = mean(Core, na.rm = TRUE)
  ) %>%
  ungroup()
