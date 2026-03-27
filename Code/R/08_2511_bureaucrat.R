pacman::p_load(dplyr, ggplot2, tidyverse,fixest,readxl,data.table,skimr,broom,purrr,writexl,fwildclusterboot)

setwd("/Users/wangze/Dropbox/Emi/Land_Project_wtichcc")
fvc_long <- read.csv("Data/processed/jiangsu_land_index/fvc_long.xlsx")
soil <- read_xlsx("../LandProtection/geodata/soil_jiangsu/Jiangsu_grid_500m_with_soil.xlsx")
soil <- soil %>% select(grid_id,soil_suit_mean,soil_suit_sd) 
fvc_long <- fvc_long %>%
  left_join(soil, by = "grid_id")

bureaucrat <- b1 

bureaucrat <- read_excel("Data/processed/jiangsu_land_index/Land_Index.xlsx",sheet = "officer_2") 
bureaucrat <- bureaucrat %>%
  mutate(Age_t = Year - 出生年份,
         tenure = Year- 任期开始年份) %>%
  rename(Nm_Prfc = City, cohort = Year)
bureaucrat <- bureaucrat %>%
  pivot_wider(
    id_cols = c(Nm_Prfc, cohort),        
    names_from = 职位名称,             
    values_from = c(姓名, 出生年份, 出生地, 学历, 性别, Age_t,tenure),
    names_glue = "{职位名称}_{.value}"   
  )
#write.csv(bureaucrat,"Data/processed/jiangsu_land_index/bureaucrat.csv")
  
fvc_long<- fvc_long %>%
  merge(bureaucrat,by=c("Nm_Prfc","cohort")) 
fvc_long <- fvc_long %>%
  mutate(eligible = ifelse(市委书记_Age_t < 58, 1, 0),
         post = if_else(cohort > 2017, 1, 0),
         soil_dum = soil_suit_mean >= 3,
         birthplace = if_else(str_detect(市委书记_出生地, "江苏") , 1, 0),
         impo = ifelse(Nm_Prfc %in% c("南京市"),1,0),
         fallow = fvc < 0.2)

bureaucrat <- read_excel("Data/processed/jiangsu_land_index/Land_Index.xlsx",sheet = "officer_2") 
bureaucrat <- bureaucrat %>%
  mutate(Age_t = Year - 出生年份,
         tenure = Year- 任期开始年份) %>%
  rename(Nm_Prfc = City, year = Year)
bureaucrat <- bureaucrat %>%
  pivot_wider(
    id_cols = c(Nm_Prfc, year),        
    names_from = 职位名称,             
    values_from = c(姓名, 出生年份, 出生地, 学历, 性别, Age_t,tenure),
    names_glue = "{职位名称}_{.value}"   
  )

#rename all variables in bureaucrat to have prefix y_
bureaucrat <- bureaucrat %>%
  rename_with(~ paste0("y_", .), -c(Nm_Prfc, year))
fvc_long<- fvc_long %>%
  merge(bureaucrat,by=c("Nm_Prfc","year"))
fvc_long <- fvc_long %>%
  mutate(eligible_y = ifelse(y_市委书记_Age_t < 58, 1, 0),
         eli = ifelse(eligible_y == 1 & eligible == 1, 1, 0),
         y_birthplace = if_else(str_detect(y_市委书记_出生地, "江苏") , 1, 0)
         )

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
  select(Nm_Cnty, Nm_Prfc, Pop_2010, gdp_2010, size, govbud_10) %>%
  group_by(Nm_Prfc) %>%
  summarise(gdp_prfc = mean(gdp_2010, na.rm = TRUE),
            Pop_prfc = sum(Pop_2010, na.rm = TRUE),
            size_prfc = sum(size, na.rm = TRUE),
            govbud_10_prfc = sum(govbud_10, na.rm = TRUE)
  ) %>% ungroup()

fvc_long <- fvc_long %>% 
  left_join(stats, by = c("Nm_Prfc"))

# fvc_long <- fvc_long %>%
#   mutate(
#     t = year - 2018,
#     Pop_t   = Pop_2010 * post,
#     GDP_t   = gdp_2010 * post,
#     size_t = size * post,
#     govbud_10_t = govbud_10 * post,
#     assess = ifelse(cohort < 2020,1,0),
#     fallow = fvc < 0.2
#   )

fvc_long <- fvc_long %>%
  mutate(
    t = year - 2018,
    Pop_t  = Pop_prfc * post,
    GDP_t   = gdp_prfc * post,
    size_t = size_prfc * post,
    govbud_10_t = govbud_10_prfc * post,
    assess = ifelse(cohort < 2020,1,0),
    fallow = fvc < 0.2,
    diff = ifelse(y_市委书记_姓名 != 市委书记_姓名,1,0))


# res <- feols(fallow~ Pressure_c:post + Pop_t + GDP_t + size_t + govbud_10_t| Nm_Cnty + cohort + year,
#              cluster = ~ Nm_Cnty,
#              data = filter(fvc_long, Core < 1& s <= 4))
# summary(res)

#好东西
res <- feols(fallow~ Pressure_c:post + soil_suit_mean:Pressure_c:post | Nm_Cnty + cohort + year,
             cluster = ~ Nm_Cnty,
             data = filter(fvc_long, Core < 1))
summary(res)

res <- feols(fallow~ Pressure_c:post + soil_dum:Pressure_c:post | Nm_Cnty + cohort + year,
             cluster = ~ Nm_Cnty,
             data = filter(fvc_long, Core < 1))
summary(res)

#以上是好东西

res <- feols(fallow~ Pressure_c:post + eligible_y:Pressure_c:post | Nm_Cnty + cohort + year + s,
             cluster = ~ Nm_Cnty,
             data = filter(fvc_long, Core < 1 & s <= 4 & (cohort <= 2019)))
summary(res)


res <- feols(fallow~ Pressure_c:post + eligible:Pressure_c:post + diff:eligible_y:Pressure_c:post| Nm_Cnty + cohort + year,
             cluster = ~ Nm_Cnty,
             data = filter(fvc_long, Core < 1& s <= 4 & (cohort <= 2022)))
summary(res)

res <- feols(fallow ~ Pressure_c:post + eligible_y:Pressure_c:post | Nm_Cnty + cohort + year,
             cluster = ~Nm_Cnty,
             data = filter(fvc_long, Core < 1 & s <= 2 & (cohort <= 2019)))
summary(res)


res <- feols(fallow ~ Pressure_c:post + eligible:Pressure_c:post| Nm_Cnty + cohort + year,
             cluster = ~Nm_Cnty,
             data = filter(fvc_long, Core < 1 & s <= 2 & (cohort <= 2019)))
summary(res)

##以下是好东西

fvc_long <- fvc_long %>% mutate(pre20 = ifelse(cohort < 2020,1,0))

res <- feols(soil_suit_mean ~ Pressure_c:post + eligible:Pressure_c:post:pre20| Nm_Cnty + cohort,
             cluster = ~Nm_Cnty,
             data = filter(fvc_long, Core < 1 & s == 1))
summary(res)

res <- feols(soil_dum ~ Pressure_c:post + eligible:Pressure_c:post:pre20| Nm_Cnty + cohort,
             cluster = ~Nm_Cnty,
             data = filter(fvc_long, Core < 1 & s == 1))
summary(res)

try <- fvc_long %>%
  mutate(x = soil_dum*Pressure_c*post, iv = eligible*Pressure_c*post)

res <- feols(
  fallow ~ Pressure_c:post |Nm_Cnty + cohort + year|
    x ~ iv ,
  cluster = ~ Nm_Cnty,
  data = filter(try, Core < 1 & cohort <= 2019 & s <= 4)
)
summary(res)



crop <- jiangsu_long %>% 
  group_by(grid_id) %>% summarise(crop_share = mean(crop_share,na.rm=TRUE)) %>% distinct()


fvc_all_long <- fvc %>%
  pivot_longer(
    cols = starts_with("fvc_"),
    names_to = "year",
    names_prefix = "fvc_",
    values_to = "fvc"
  ) %>%
  mutate(year = as.numeric(year))
fvc_all_long <- fvc_all_long %>%
  merge(soil,by=c("grid_id")) 
fvc_all_long <- fvc_all_long %>%
  left_join(crop,by=c("grid_id"))
fvc_all_long <- fvc_all_long %>%
  mutate(soil_4 = soil_suit_mean >= 5,
         fallow = fvc < 0.2)
res <- feols(fallow ~ soil_4,
             cluster = ~grid_id,
             data = filter(fvc_all_long,crop_share > 0.6) )
summary(res)

