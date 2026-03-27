pacman::p_load(dplyr, ggplot2, tidyverse,fixest,readxl,data.table,skimr,broom,purrr,writexl,fwildclusterboot)
setwd("/Users/wangze/Dropbox/Emi/my_project_claude")
imper <- read.csv("../LandProtection/geodata/Jiangsu_CGCS2000/Jiangsu_grid_impervious_2012_2022.csv")
index <- read_xlsx("Data/processed/jiangsu_land_index/Land_Pressure_Index_List.xlsx")
jiangsu_long <- read.csv("Data/processed/jiangsu_land_index/jiangsu_long.csv")
jiangsu_long <- jiangsu_long %>%
  left_join(imper, by = c("grid_id", "year")) %>% mutate(
    impervious_area_m2 = impervious_area_m2 /250000
  )
## generate ggplot showing the trend of impervious surface from 2012 to 2022 for high and low pressure areas
ind <- index %>% select(Nm_Prfc,CityStress_p) %>% distinct() 
jiangsu_long <- jiangsu_long %>%
  mutate(core10 = ifelse(Core == 1, 1, 0))
p <- jiangsu_long %>% 
  group_by(Nm_Prfc,year, core10) %>% summarize(Impervious = sum(impervious_area_m2, na.rm = TRUE)*25,
                                  Crop = sum(crop_share,na.rm = TRUE)*25) %>%
  left_join(ind, by = "Nm_Prfc") %>% na.omit() %>% ungroup()
p <- p %>% mutate(Pressure_dum = CityStress_p > median(CityStress_p, na.rm = TRUE))
p <- p %>% rename(Cropland = Crop)
p_long <- p %>%
  pivot_longer(
    cols = c("Impervious", "Cropland"),
    names_to = "var",
    values_to = "value"
  ) %>%
  mutate(
    Pressure = ifelse(Pressure_dum, "High Pressure", "Low Pressure"),
    core = ifelse(core10 == 1, "Core Urban", "Non-core")
  )
p_long <- p_long %>%
  group_by(Nm_Prfc, var, core10) %>%
  mutate(value_dm = value - mean(value, na.rm = TRUE)) %>%
  ungroup()

###############Figure: Motivating_size##############
ggplot(p_long,
       aes(x = year, y = value_dm,
           linetype = Pressure,   # ← 用线型区分 high/low
           group = Pressure)) +
  
  stat_summary(fun = mean, geom = "line", size = 1.1, color = "black") +   # ← 统一颜色
  stat_summary(fun = mean, geom = "point", size = 2, color = "black") +    # ← 统一颜色
  
  # --- Policy year line ---
  geom_vline(xintercept = 2017, linetype = "dashed", color = "black", size = 0.6) +
  
  # --- Line types for pressure levels ---
  scale_linetype_manual(values = c("High Pressure" = "solid",
                                   "Low Pressure" = "dashed")) +
  
  # --- Facet (2×2) ---
  facet_grid(var ~ core, scales = "free_y") +
  
  # --- Labels ---
  labs(
    title = "Prefecture-Demeaned Trends of Impervious and Cropland",
    x = "Year",
    y = "Prefecture-demeaned size (ha)",
    linetype = "Prefecture Type"
  ) +
  
  # --- Themes ---
  theme_classic(base_family = "PingFang SC") +
  theme(
    panel.grid.minor = element_blank(),
    strip.text = element_text(size = 14, face = "bold"),
    axis.title.x = element_text(size = 10, face = "bold")
  ) +
  
  # --- Only show 2017 at x-axis ---
  scale_x_continuous(breaks = 2017)

names(jiangsu_long)

bu <- read.csv("Data/processed/jiangsu_land_index/bureaucrat.csv") %>% rename(year = cohort)
jiangsu_long <- jiangsu_long %>%
  left_join(bu, by = c("Nm_Prfc", "year"))
jiangsu_long <- jiangsu_long %>%
  mutate(eligible = ifelse(市委书记_Age_t < 58, 1, 0),
         post = if_else(year > 2017, 1, 0),
         birthplace = if_else(str_detect(市委书记_出生地, "江苏") , 1, 0),
         pressure_dum_prfc = CityStress_p > median(CityStress_p, na.rm = TRUE))
es_model_twfe_bu <- feols(
  impervious_area_m2 ~ CityStress_p:post| grid_id + year,
  cluster = ~Nm_Prfc,
  data = filter(jiangsu_long,Core == 1)
)
summary(es_model_twfe_bu)

