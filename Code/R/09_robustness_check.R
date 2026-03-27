pacman::p_load(dplyr, ggplot2, tidyverse,fixest,readxl,data.table,skimr,broom,purrr,writexl,modelsummary,tibble,kableExtra,data.table)


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

#---------Import Cropland and FVC data-----------
fvc <- read.csv("../LandProtection/geodata/Jiangsu_CGCS2000/Jiangsu_grid_fvcavg_2012_2022.csv")
fvc <- fvc %>% filter(!is.na(fvc_2012))
jiangsu <- read.csv("../LandProtection/data/Jiangsu/jiangsu_crop_ready.csv")
jiangsu <- left_join(jiangsu,index %>% select(Nm_Prfc,Nm_Cnty,Core, Pressure_c),by=c("Nm_Prfc","Nm_Cnty"))

#################### Sensitivity Analysis: Fallow (Alternative Definition on Reclaimed Land)###############

# 在你现有代码中、for 循环之前加上这一行：
jiangsu_base <- jiangsu

# fvc 做完过滤以后
fvc <- fvc %>% filter(!is.na(fvc_2012))
fvc_base <- fvc   # 作为原始 fvc 备份


estimate_fallow_ate <- function(cutoff) {
  
  # ---- ① 以当前 cutoff 重新定义 reclaimed_2013:2021 ----
  dt <- as.data.table(jiangsu_base)  # 每次从同一个原始 jiangsu 开始
  
  for (yr in 2013:2021) {
    col_now  <- paste0("crop_share_", yr)
    col_prev <- paste0("crop_share_", yr - 1)
    col_next <- paste0("crop_share_", yr + 1)
    new_col  <- paste0("reclaimed_", yr)
    
    dt[, (new_col) := get(col_prev) < cutoff & get(col_now)>0.7 & get(col_next)>0.7 ]
  }
  
  year_cols   <- grep("^reclaimed_", names(dt), value = TRUE)
  year_labels <- as.numeric(sub("reclaimed_", "", year_cols))
  reclaimed_matrix <- as.matrix(dt[, ..year_cols])
  
  first_year_index <- apply(reclaimed_matrix, 1, function(x) {
    i <- which(x == 1)
    if (length(i) == 0) NA_integer_ else year_labels[min(i)]
  })
  
  # ---- ② 按照你的写法重新构造 jiangsu_cohort ----
  jiangsu_cohort <- dt[, .(grid_id, Nm_Prfc, Nm_Cnty, Core, Pressure_c)]
  jiangsu_cohort[, cohort := first_year_index]
  jiangsu_cohort <- jiangsu_cohort[cohort >= 2013 & cohort <= 2021]
  jiangsu_cohort <- na.omit(jiangsu_cohort)
  
  # 如果样本太小，直接返回 NA，避免回归报错
  if (nrow(jiangsu_cohort) < 50) {
    return(tibble(
      cutoff = cutoff,
      coef_W = NA_real_,
      se_W   = NA_real_,
      nobs   = nrow(jiangsu_cohort)
    ))
  }
  
  # ---- ③ 用这一批“新增耕地格子”去匹配 fvc，并宽转长 ----
  fvc_tmp <- fvc_base %>%
    semi_join(as.data.frame(jiangsu_cohort), by = "grid_id")
  
  fvc_long_tmp <- fvc_tmp %>%
    pivot_longer(
      cols = starts_with("fvc_"),
      names_to = "year",
      names_prefix = "fvc_",
      values_to = "fvc"
    ) %>%
    mutate(year = as.numeric(year)) %>%
    left_join(as.data.frame(jiangsu_cohort), by = "grid_id") %>%
    mutate(
      s = year - cohort,
      W = (cohort >= 2018) * (Pressure_c),
      fallow = fvc < 0.2
    ) %>%
    filter(s %in% c(1, 2, 3, 4))
  
  # 同你 baseline：只用 Core < 1 的“非核心”样本
  fvc_long_tmp <- fvc_long_tmp %>% filter(Core < 1)
  
  if (nrow(fvc_long_tmp) < 50) {
    return(tibble(
      cutoff = cutoff,
      coef_W = NA_real_,
      se_W   = NA_real_,
      nobs   = nrow(fvc_long_tmp)
    ))
  }
  
  # ---- ④ 跑与你 baseline 完全相同的回归 ----
  est <- feols(
    fallow ~ W | Nm_Cnty + cohort + s,
    cluster = ~Nm_Cnty,
    data = fvc_long_tmp
  )
  
  tibble(
    cutoff = cutoff,
    coef_W = coef(est)["W"],
    se_W   = se(est)["W"],
    nobs   = nobs(est)
  )
}

# 你想考察的 cutoff 序列
cutoff_grid <- seq(0.55, 0.65, by = 0.01)

robust_res <- map_dfr(cutoff_grid, estimate_fallow_ate) %>%
  mutate(
    lb = coef_W - 1.96 * se_W,
    ub = coef_W + 1.96 * se_W
  )

# 看一下结果
robust_res

# 画图
ggplot(robust_res, aes(x = cutoff, y = coef_W)) +
  geom_line(size = 1) +
  geom_ribbon(aes(ymin = lb, ymax = ub), alpha = 0.2) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(
    x = "Threshold for previous-year cropland share",
    y = "Coefficient",
    title = "Robustness of fallow rate to alternative reclaimed-land definitions"
  ) +
  theme_minimal(base_size = 14)


##---------------------Sensitivity Analysis: Soil (Alternative Definition on Reclaimed Land)------------------------
soil <- read_xlsx("../LandProtection/geodata/soil_jiangsu/Jiangsu_grid_500m_with_soil.xlsx")
soil <- soil %>% select(grid_id, soil_suit_mean, soil_suit_sd)
soil_base <- soil

estimate_soil_ate_lowcut <- function(low_cut) {
  
  # ---- ① 用 low_cut 重新定义 reclaimed_2013:2021（与 baseline 同一类定义）----
  dt <- as.data.table(jiangsu_base)  # 每次从原始 jiangsu 开始
  
  for (yr in 2013:2021) {
    col_now  <- paste0("crop_share_", yr)
    col_prev <- paste0("crop_share_", yr - 1)
    col_next <- paste0("crop_share_", yr + 1)
    new_col  <- paste0("reclaimed_", yr)
    
    # baseline: crop_{t-1} < 0.6 & crop_t > 0.7 & crop_{t+1} > 0.7
    # robustness: 把 0.6 换成 low_cut
    dt[, (new_col) := 
         (get(col_prev) < low_cut) &
         (get(col_now)  > 0.7)     &
         (get(col_next) > 0.7)]
  }
  
  year_cols   <- grep("^reclaimed_", names(dt), value = TRUE)
  year_labels <- as.numeric(sub("reclaimed_", "", year_cols))
  reclaimed_matrix <- as.matrix(dt[, ..year_cols])
  
  first_year_index <- apply(reclaimed_matrix, 1, function(x) {
    i <- which(x == 1)
    if (length(i) == 0) NA_integer_ else year_labels[min(i)]
  })
  
  # ---- ② 构造 jiangsu_cohort ----
  jiangsu_cohort <- dt[, .(grid_id, Nm_Prfc, Nm_Cnty, Core, Pressure_c)]
  jiangsu_cohort[, cohort := first_year_index]
  jiangsu_cohort <- jiangsu_cohort[cohort >= 2012 & cohort <= 2021]
  jiangsu_cohort <- na.omit(jiangsu_cohort)
  
  if (nrow(jiangsu_cohort) < 50) {
    return(tibble(
      low_cut = low_cut,
      coef_W  = NA_real_,
      se_W    = NA_real_,
      nobs    = nrow(jiangsu_cohort)
    ))
  }
  
  # ---- ③ 匹配 fvc，宽转长 ----
  fvc_tmp <- fvc_base %>%
    semi_join(as.data.frame(jiangsu_cohort), by = "grid_id")
  
  fvc_long_tmp <- fvc_tmp %>%
    pivot_longer(
      cols       = starts_with("fvc_"),
      names_to   = "year",
      names_prefix = "fvc_",
      values_to  = "fvc"
    ) %>%
    mutate(year = as.numeric(year)) %>%
    left_join(as.data.frame(jiangsu_cohort), by = "grid_id") %>%
    mutate(
      s = year - cohort,
      W = (cohort >= 2018) * (Pressure_c)
    )
  
  # ---- ④ 合并土壤数据，构造 soil_3 ----
  soil_reclaimed_tmp <- fvc_long_tmp %>%
    left_join(soil_base, by = "grid_id") %>%
    mutate(
      soil_3 = (soil_suit_mean)
    ) %>%
    # soil baseline：Core < 1 且 s == 3（开垦后第 3 年）
    filter(Core < 1,  cohort <= 2019 , s == 3)
  
  if (nrow(soil_reclaimed_tmp) < 50) {
    return(tibble(
      low_cut = low_cut,
      coef_W  = NA_real_,
      se_W    = NA_real_,
      nobs    = nrow(soil_reclaimed_tmp)
    ))
  }
  
  # ---- ⑤ soil 回归：与之前 soil_dum 的 specification 对齐 ----
  est <- feols(
    soil_3 ~ W | Nm_Cnty + cohort,
    cluster = ~Nm_Cnty,
    data    = soil_reclaimed_tmp
  )
  
  tibble(
    low_cut = low_cut,
    coef_W  = coef(est)["W"],
    se_W    = se(est)["W"],
    nobs    = nobs(est)
  )
}

low_grid_soil <- seq(0.55, 0.65, by = 0.01)

soil_robust <- map_dfr(low_grid_soil, estimate_soil_ate_lowcut) %>%
  mutate(
    lb = coef_W - 1.96 * se_W,
    ub = coef_W + 1.96 * se_W
  )

soil_robust

ggplot(soil_robust, aes(x = low_cut, y = coef_W)) +
  geom_line(size = 1) +
  geom_ribbon(aes(ymin = lb, ymax = ub), alpha = 0.2) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(
    x = "Threshold for previous-year cropland share",
    y = "Coefficient",
    title = "Robustness of soil quality to alternative reclaimed-land definitions"
  ) +
  theme_minimal(base_size = 14)


##---------------------Sensitivity Analysis: Fallow Rate (Alternative Definition on Fallow)------------------------


estimate_fallow_ate <- function(fallow_cut) {
  
  # ---- ① 用固定阈值重新定义 reclaimed_2013:2021 ----
  dt <- as.data.table(jiangsu_base)  # 每次从同一个原始 jiangsu 开始
  
  for (yr in 2013:2021) {
    col_now  <- paste0("crop_share_", yr)
    col_prev <- paste0("crop_share_", yr - 1)
    col_next <- paste0("crop_share_", yr + 1)
    new_col  <- paste0("reclaimed_", yr)
    
    # 固定定义：crop_{t-1} < 0.6 & crop_t > 0.7 & crop_{t+1} > 0.7
    dt[, (new_col) := 
         (get(col_prev) < 0.6) &
         (get(col_now)  > 0.7) &
         (get(col_next) > 0.7)]
  }
  
  year_cols   <- grep("^reclaimed_", names(dt), value = TRUE)
  year_labels <- as.numeric(sub("reclaimed_", "", year_cols))
  reclaimed_matrix <- as.matrix(dt[, ..year_cols])
  
  first_year_index <- apply(reclaimed_matrix, 1, function(x) {
    i <- which(x == 1)
    if (length(i) == 0) NA_integer_ else year_labels[min(i)]
  })
  
  # ---- ② 构造 jiangsu_cohort ----
  jiangsu_cohort <- dt[, .(grid_id, Nm_Prfc, Nm_Cnty, Core, Pressure_c)]
  jiangsu_cohort[, cohort := first_year_index]
  jiangsu_cohort <- jiangsu_cohort[cohort >= 2013 & cohort <= 2021]
  jiangsu_cohort <- na.omit(jiangsu_cohort)
  
  if (nrow(jiangsu_cohort) < 50) {
    return(tibble(
      fallow_cut = fallow_cut,
      coef_W     = NA_real_,
      se_W       = NA_real_,
      nobs       = nrow(jiangsu_cohort)
    ))
  }
  
  # ---- ③ 用这一批“新增耕地格子”去匹配 fvc，并宽转长 ----
  fvc_tmp <- fvc_base %>%
    semi_join(as.data.frame(jiangsu_cohort), by = "grid_id")
  
  fvc_long_tmp <- fvc_tmp %>%
    pivot_longer(
      cols        = starts_with("fvc_"),
      names_to    = "year",
      names_prefix= "fvc_",
      values_to   = "fvc"
    ) %>%
    mutate(year = as.numeric(year)) %>%
    left_join(as.data.frame(jiangsu_cohort), by = "grid_id") %>%
    mutate(
      s      = year - cohort,
      W      = (cohort >= 2018) * (Pressure_c),
      # 关键：这里用传入的阈值定义 fallow
      fallow = fvc < fallow_cut
    ) %>%
    filter(s %in% c(1, 2, 3, 4)) 
  
  fvc_long_tmp <- fvc_long_tmp %>% filter(Core < 1)
  
  if (nrow(fvc_long_tmp) < 50) {
    return(tibble(
      fallow_cut = fallow_cut,
      coef_W     = NA_real_,
      se_W       = NA_real_,
      nobs       = nrow(fvc_long_tmp)
    ))
  }
  
  # ---- ④ 回归：与 baseline 相同 specification ----
  est <- feols(
    fallow ~ W | Nm_Cnty + cohort + s,
    cluster = ~Nm_Cnty,
    data    = fvc_long_tmp
  )
  
  tibble(
    fallow_cut = fallow_cut,
    coef_W     = coef(est)["W"],
    se_W       = se(est)["W"],
    nobs       = nobs(est)
  )
}

fallow_grid <- seq(0.13, 0.2, by = 0.01)

robust_res <- map_dfr(fallow_grid, estimate_fallow_ate) %>%
  mutate(
    lb = coef_W - 1.96 * se_W,
    ub = coef_W + 1.96 * se_W
  )

robust_res

ggplot(robust_res, aes(x = fallow_cut, y = coef_W)) +
  geom_line(size = 1) +
  geom_ribbon(aes(ymin = lb, ymax = ub), alpha = 0.2) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(
    x = "Threshold defining fallow (FVC < cutoff)",
    y = "Coefficient",
    title = "Robustness of fallow rate to alternative fallow definitions"
  ) +
  theme_minimal(base_size = 14)



