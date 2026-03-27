setwd("/Users/wangze/Dropbox/Emi/my_project_claude")
library(tidyverse)
library(dplyr)
library(knitr)
library(haven)
library(openxlsx)
library(tinytex)
library(skimr)
library(ggplot2)
library(readxl)

#####Data Prep#####
## Jiangsu
provinf <- read_excel("../LandProtection/data/Jiangsu/Grid_3km_allinfo.xls")
mean11 <- read_excel("../LandProtection/data/Jiangsu/mean11.xls")
mean12 <- read_excel("../LandProtection/data/Jiangsu/mean12.xls")
###!! Why less obs? please check
mean13 <- read_excel("../LandProtection/data/Jiangsu/mean13_new.xls")
mean14 <- read_excel("../LandProtection/data/Jiangsu/mean14.xls")
mean15 <- read_excel("../LandProtection/data/Jiangsu/mean15.xls")
mean16 <- read_excel("../LandProtection/data/Jiangsu/mean16.xls")
mean17 <- read_excel("../LandProtection/data/Jiangsu/mean17.xls")
mean18 <- read_excel("../LandProtection/data/Jiangsu/mean18.xls")
mean19 <- read_excel("../LandProtection/data/Jiangsu/mean19.xls")
mean20 <- read_excel("../LandProtection/data/Jiangsu/mean20.xls")
mean21 <- read_excel("../LandProtection/data/Jiangsu/mean21.xls")
mean22 <- read_excel("../LandProtection/data/Jiangsu/mean22.xls")
y11 <- merge(provinf,mean11,by = c("FID"),all.x = TRUE)
y12 <- merge(provinf,mean12,by = c("FID"),all.x = TRUE)
y13 <- merge(provinf,mean13,by = c("FID"),all.x = TRUE)
y14 <- merge(provinf,mean14,by = c("FID"),all.x = TRUE)
y15 <- merge(provinf,mean15,by = c("FID"),all.x = TRUE)
y16 <- merge(provinf,mean16,by = c("FID"),all.x = TRUE)
y17 <- merge(provinf,mean17,by = c("FID"),all.x = TRUE)
y18 <- merge(provinf,mean18,by = c("FID"),all.x = TRUE)
y19 <- merge(provinf,mean19,by = c("FID"),all.x = TRUE)
y20 <- merge(provinf,mean20,by = c("FID"),all.x = TRUE)
y21 <- merge(provinf,mean21,by = c("FID"),all.x = TRUE)
y22 <- merge(provinf,mean22,by = c("FID"),all.x = TRUE)
y11$yr <- 2011
y12$yr <- 2012
y13$yr <- 2013
y14$yr <- 2014
y15$yr <- 2015
y16$yr <- 2016
y17$yr <- 2017
y18$yr <- 2018
y19$yr <- 2019
y20$yr <- 2020
y21$yr <- 2021
y22$yr <- 2022
jiangsu <- rbind(y11,y12,y13,y14,y15,y16,y17,y18,y19,y20,y21,y22)

jiangsu$urban <- ifelse(grepl("区$",jiangsu$Nm_Cnty),1,0)

##bureaucrat: the merge method used now is not correct, please check
bureaucrats <- read.csv("Data/processed/bureaucrat.csv",fileEncoding = "GB18030")
# FILTER IF administrative_name contains 江苏省
bureau_jiangsu <- bureaucrats %>% 
  filter(grepl("江苏省", administrative_name) & tenure_end > 2017 & position == "市委书记")
# mutate if else (birthplace contains "江苏")
# bureau_jiangsu <- bureau_jiangsu %>% 
#   mutate(birth_jiangsu = ifelse(grepl("江苏", birthplace), 1, 0))
# bureau_jiangsu <- bureau_jiangsu %>%
#   group_by(administrative_code) %>% summarise(n=sum(birth_jiangsu)/n())

bureau_jiangsu <- bureau_jiangsu %>%
  mutate(age_dum = ifelse((birthyear >= 1962 & tenure_begin <= 2017) | ((tenure_begin - birthyear <= 56) & tenure_begin > 2017), 1, 0))
bureau_jiangsu <- bureau_jiangsu %>% group_by(administrative_code) %>% summarise(n= sum(age_dum)/n())
#mutate Cd_prfc = first four digits in administrative_code
bureau_jiangsu <- bureau_jiangsu %>%
  mutate(Cd_Prfc = as.numeric(substr(administrative_code, 1, 4)))
jiangsu <- jiangsu %>% 
  mutate(Cd_Prfc = as.numeric(Cd_Prfc))
# Merge with jiangsu data
jiangsu <- merge(jiangsu, bureau_jiangsu, by = c("Cd_Prfc"), all.x = TRUE)



jiangsu_mdensity <- jiangsu %>% filter(urban == 1) %>%
  group_by(Nm_Prfc) %>% summarise(mean_density = mean(Density)) %>% arrange(mean_density)
sum1 <- jiangsu %>% group_by(Nm_Prfc) %>% 
  summarise(sum_area = sum(Area))
sum2 <- jiangsu %>% group_by(Nm_Prfc) %>% 
  filter(urban == 1) %>% summarise(sum_urban = sum(Area))
jiangsu_area <- merge(sum1, sum2, by = c("Nm_Prfc")) %>% 
  mutate(share_urban = round(sum_urban/sum_area,4)) %>% arrange(share_urban)
jiangsu_area

jiangsu <- merge(jiangsu, jiangsu_area, by = c("Nm_Prfc"), all.x = TRUE)
jiangsu <- merge(jiangsu, jiangsu_mdensity, by = c("Nm_Prfc"), all.x = TRUE)

jiangsu_highden <- jiangsu %>% mutate(high_urban = if_else(n == 1,"Young","Old"))
jiangsu_u <- jiangsu_highden %>% group_by(yr,high_urban) %>% summarise(mean_crop = mean(MEAN,na.rm = TRUE))
mean <- jiangsu_u %>% group_by(high_urban) %>% summarise(mean = mean(mean_crop))
jiangsu_u <- jiangsu_u %>% mutate(mean_crop = if_else(high_urban == "Young", mean_crop - mean$mean[[2]],mean_crop - mean$mean[[1]]))
p <- ggplot(data = filter(jiangsu_u),aes(x = yr, y = mean_crop))
p <- p + geom_point() + geom_line() + scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
p <- p + facet_wrap(.~high_urban) + theme_few()
p <- p + labs(title = "Cropland change in the top 1 GDP province", y = "Cropland share per 3km X 3km grid (Demeaned)")
p
