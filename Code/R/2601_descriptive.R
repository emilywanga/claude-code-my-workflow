pacman::p_load(dplyr, ggplot2, tidyverse,fixest,readxl,data.table,skimr,broom,purrr,writexl,modelsummary,tibble,kableExtra)


setwd("/Users/wangze/Dropbox/Emi/my_project_claude")
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


####-----------boxplot of LandShare_c by Nm_Prfc-----------####
plot_df <- index %>%
  filter(Core < 1) %>%
  distinct(Nm_Prfc, Nm_Cnty, Pressure_c) %>%
  filter(!is.na(Pressure_c), is.finite(Pressure_c))

ggplot(plot_df,
            aes(x = reorder(Nm_Prfc, Pressure_c, FUN = median),
                y = Pressure_c)) +
  geom_boxplot(outlier.shape = NA) +
  geom_jitter(width = 0.15, alpha = 0.6, size = 1) +
  labs(
    x = "Prefecture",
    y = "Pressure index"
  ) +
  theme_classic() +
  theme(
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank()
  )
ggsave("Results/Figures/Pressure_c_boxplot.png", width = 6, height = 4, dpi = 300)

####-----------Variance Decomposition: Between-p and Within-p -----------####
vd_df <- index %>%
  filter(Core < 1) %>%
  select(Nm_Prfc, Pressure_c) %>%
  filter(!is.na(Pressure_c), is.finite(Pressure_c))

X_bar <- mean(vd_df$Pressure_c)

TSS <- sum( (vd_df$Pressure_c - X_bar)^2 )

vd_stats <- vd_df %>%
  group_by(Nm_Prfc) %>%
  summarise(
    mean_p = mean(Pressure_c),
    n_p    = n(),
    .groups = "drop"
  )

SS_between <- sum( vd_stats$n_p * (vd_stats$mean_p - X_bar)^2 )
vd_df <- vd_df %>%
  left_join(vd_stats, by = "Nm_Prfc")

SS_within <- sum( (vd_df$Pressure_c - vd_df$mean_p)^2 )

share_between <- SS_between / TSS
share_within  <- SS_within  / TSS

share_between
share_within
share_between + share_within


