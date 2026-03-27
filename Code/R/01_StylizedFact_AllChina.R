
library(tidyverse)
library(dplyr)
library(knitr)
library(haven)
library(openxlsx)
library(tinytex)
library(skimr)
library(ggplot2)
library(readxl)
library(ggthemes)
library(fixest)

setwd("/Users/wangze/Dropbox/Emi/my_project_claude")

provinf <- read_excel("Data/processed/china_attribute.xlsx")
land04 <- read.csv("../LandProtection/data/Allcounty/CLCD_v01_2004_县.csv")
land05 <- read.csv("../LandProtection/data/Allcounty/CLCD_v01_2005_县.csv")
land06 <- read.csv("../LandProtection/data/Allcounty/CLCD_v01_2006_县.csv")
land07 <- read.csv("../LandProtection/data/Allcounty/CLCD_v01_2007_县.csv")
land08 <- read.csv("../LandProtection/data/Allcounty/CLCD_v01_2008_县.csv")
land09 <- read.csv("../LandProtection/data/Allcounty/CLCD_v01_2009_县.csv")
land10 <- read.csv("../LandProtection/data/Allcounty/CLCD_v01_2010_县.csv")
land11 <- read.csv("../LandProtection/data/Allcounty/CLCD_v01_2011_县.csv")
land12 <- read.csv("../LandProtection/data/Allcounty/CLCD_v01_2012_县.csv")
land13 <- read.csv("../LandProtection/data/Allcounty/CLCD_v01_2013_县.csv")
land14 <- read.csv("../LandProtection/data/Allcounty/CLCD_v01_2014_县.csv")
land15 <- read.csv("../LandProtection/data/Allcounty/CLCD_v01_2015_县.csv")
land16 <- read.csv("../LandProtection/data/Allcounty/CLCD_v01_2016_县.csv")
land17 <- read.csv("../LandProtection/data/Allcounty/CLCD_v01_2017_县.csv")
land18 <- read.csv("../LandProtection/data/Allcounty/CLCD_v01_2018_县.csv")
land19 <- read.csv("../LandProtection/data/Allcounty/CLCD_v01_2019_县.csv")
land20 <- read.csv("../LandProtection/data/Allcounty/CLCD_v01_2020_县.csv")
land21 <- read.csv("../LandProtection/data/Allcounty/CLCD_v01_2021_县.csv")
land22 <- read.csv("../LandProtection/data/Allcounty/CLCD_v01_2022_县.csv")
land <- rbind(land04,land05,land06,land07, land08, land09, land10, land11, land12, land13, land14, land15, land16, land17, land18, land19, land20, land21, land22)
land <- land %>% rename("Nm_Cnty" = "县", "Cd_Cnty" = "县代码",
                "Nm_Prfc" = "市", "Cd_Prfc" = "市代码",
                "Nm_Prvn" = "省", "Cd_Prvn" = "省代码",
                "Tp_Prvn" = "省类型", "Tp_Cnty" = "县类型", "Tp_Prfc" = "市类型",
                "yr" = "年份")
provinf <- provinf %>% select(-c("studyar"))
land <- merge(land,provinf, by = c("Cd_Cnty"), all.x = TRUE)
land <- land %>% select(-c("Nm_Prfc.y", "Nm_Prvn.y","Cd_Prfc.y", "Cd_Prvn.y")) %>%
  rename("Nm_Prvn" = "Nm_Prvn.x", "Nm_Prfc" = "Nm_Prfc.x", "Nm_Cnty" = "Nm_Cnty.y", "Cd_Prvn" = "Cd_Prvn.x", "Cd_Prfc" = "Cd_Prfc.x",)
land <- land %>% mutate(urban = if_else(Tp_Cnty == "市辖区", 1, 0))
land <- land %>% 
  mutate(across(c(Cropland, Forest, Grassland, Water, Barren, Impervious, Shrub, Wetland, Sonw_Ice), ~if_else(is.na(.), 0, .)))
land <- land %>% mutate(Crop_Share = Cropland/(Cropland + Forest + Grassland + Water + Barren + Impervious + Shrub + Wetland + Sonw_Ice))
land <- land %>% filter(Tp_Prvn == "省")

land_mdensity <- land %>% filter(urban == 1) %>% group_by(Cd_Prfc) %>% summarise(mean_density = mean(Density)) %>% arrange(mean_density)
sum1 <- land %>% group_by(Cd_Prfc) %>% summarise(sum_area = sum(Area,na.rm = TRUE))
sum2 <- land %>% group_by(Cd_Prfc) %>% filter(urban == 1) %>% summarise(sum_urban = sum(Area, na.rm = TRUE))
land_area <- merge(sum1, sum2, by = c("Cd_Prfc")) %>% mutate(share_urban = round(sum_urban/sum_area,4)) %>% arrange(share_urban)
land_area

land <- merge(land, land_area, by = c("Cd_Prfc"), all.x = TRUE)
land <- merge(land, land_mdensity, by = c("Cd_Prfc"), all.x = TRUE)

land_marea <- land %>% group_by(Cd_Prvn) %>% summarise(Prvn_mshareurban = mean(share_urban, na.rm = TRUE) + 0.1, Prvn_mdensity = mean(mean_density, na.rm = TRUE))
land <- merge(land, land_marea, by = c("Cd_Prvn"), all.x = TRUE)

land <- land %>% mutate(high_urban = if_else(share_urban > Prvn_mshareurban, 1,0))

land <- land %>% filter(!is.na(share_urban))

p_land <- land  %>% filter(  Nm_Prfc %in% c("苏州市")) %>% group_by(yr, urban) %>% summarise(mean_crop = mean(Cropland,na.rm = TRUE) )
p <- ggplot(data = filter(p_land, yr >=2010),aes(x = yr, y = mean_crop)) + facet_wrap(.~ urban)
p <- p + geom_point() + geom_line() + scale_x_continuous(breaks = 2010:2022, labels = as.character(2010:2022)) 
p

p_land <- land %>% filter(Nm_Prvn %in% c("江苏省", "广东省", "浙江省")) %>% group_by(yr) %>% summarise(mean_crop = mean(Cropland,na.rm = TRUE))
p <- ggplot(data = filter(p_land),aes(x = yr, y = mean_crop))
p <- p + geom_point() + geom_line() + scale_x_continuous(breaks = 2004:2022, labels = as.character(2004:2022)) 
p

china_reg <- land %>% mutate(Treatment = if_else(yr > 2017, share_urban,0),
                             Treatment_urban = Treatment * urban)
formula <- as.formula(paste( "Crop_Share ~ Treatment |yr + Cd_Cnty"))
lm <- china_reg %>% 
  filter( yr >= 2010 & urban == 1) %>%
  feols(formula, data = ., cluster = ~ Cd_Prfc)
summary(lm)

##Event Study
years <- land %>% distinct(yr) %>% arrange(yr) %>% pull()
for (i in years) {
  column_name <- paste("T", i, sep = "")
  land <- land %>% mutate(!!sym(column_name) := if_else(yr == i, share_urban, 0))
}
formula <- as.formula(paste( "Cropland ~ ", paste0(paste("T",years[7:13],sep = ""),collapse = "+"), "+", paste0(paste("T",years[15:19],sep = ""),collapse = "+"),  "|yr + Cd_Cnty"))
lm <- land %>% 
  filter( yr >= 2010 & urban == 1 & !(Nm_Prvn %in% c("海南省"))) %>%
  feols(formula, data = ., cluster = ~ Cd_Cnty)
summary(lm)


chinastat <- read_excel("Data/processed/Cropland_ChinaStat.xlsx")
names(chinastat)
p <- ggplot(filter(chinastat,Region == "中国"),aes(x = Yr, y = Cropland_Hec)) + geom_point() + geom_line()
p

land_c <- land %>% group_by(yr) %>% summarise(Cropland_Share = sum(Cropland)/sum((Cropland + Forest + Grassland + Water + Barren + Impervious + Shrub + Wetland + Sonw_Ice)))
p <- ggplot(filter(land_c),aes(x = yr, y = Cropland_Share)) + theme_few() + geom_point() + geom_line()
p <- p + labs(title = "Cropland share in China", caption = "Data Source: CLCD data, derived from Yang, Jie and Huang, Xin (2021).")
p

land_c <- land %>% filter(Nm_Prvn %in% c("北京市","上海市","江苏省","福建省","浙江省","天津市","广东省")) %>% group_by(yr) %>% summarise(Cropland_Share = sum(Cropland)/sum((Cropland + Forest + Grassland + Water + Barren + Impervious + Shrub + Wetland + Sonw_Ice)))
p <- ggplot(filter(land_c),aes(x = yr, y = Cropland_Share)) + theme_few() + geom_point() + geom_line()
p <- p + labs(title = "Cropland share in provinces with top 6 GDP per capita in China", caption = "Data Source: CLCD data, derived from Yang, Jie and Huang, Xin (2021).")
p



#***********----------------background_crop---------------***************
land_c <- land %>% group_by(yr) %>% summarise(Cropland_Share = sum(Cropland)/sum((Cropland + Forest + Grassland + Water + Barren + Impervious + Shrub + Wetland + Sonw_Ice)))
p <- ggplot(filter(land_c),aes(x = yr, y = Cropland_Share)) + theme_few() + geom_point() + geom_line()
p <- p + labs(y = "Share of cropland pixels in total land-cover pixels",
              x = "Year")
p

land_c <- land %>% filter(Nm_Prvn %in% c("北京市","上海市","江苏省","福建省","浙江省","广东省")) %>% group_by(yr) %>% summarise(Cropland_Share = sum(Cropland)/sum((Cropland + Forest + Grassland + Water + Barren + Impervious + Shrub + Wetland + Sonw_Ice)))
p <- ggplot(filter(land_c),aes(x = yr, y = Cropland_Share)) + theme_few() + geom_point() + geom_line()
p <- p + labs(y = "Share of cropland pixels in total land-cover pixels",
              x = "Year")
p


