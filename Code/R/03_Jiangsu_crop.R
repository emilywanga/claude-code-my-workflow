setwd("/Users/wangze/Dropbox/Emi/Land_Project_wtichcc")
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
output <- read_excel("../LandProtection/data/crop_info_county/县域农产品面板数据.xlsx") %>% filter(所属省份=="江苏省")
landsize <- read_excel("../LandProtection/data/crop_info_county/中国各县域农作物播种面积数据（2000-2021年）.xlsx")  %>% 
  filter(所属省份=="江苏省") %>% select("统计年度","县域代码","播种面积-公顷")
output <- merge(output,landsize,by = c("统计年度","县域代码"),all.x = TRUE) 
output <- output %>%
  rename(
    crop_area = "播种面积-公顷",
    crop_name = "产品种类或名称",
    Nm_Prfc = "所属地级市",
    county_code = "县域代码",
    county_name = "县域名称",
    province_name = "所属省份",
    yr = "统计年度",
    output = "产量"
  ) %>% mutate(output_per_hec = round(output*1000/crop_area,2),
               yr = as.numeric(yr))

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
jiangsu_mdensity <- jiangsu %>% filter(urban == 1) %>%
  group_by(Nm_Prfc) %>% summarise(mean_density = mean(Density)) %>% arrange(mean_density)
sum1 <- jiangsu %>% group_by(Nm_Prfc) %>% 
  summarise(sum_area = sum(Area))
sum2 <- jiangsu %>% group_by(Nm_Prfc) %>% 
  filter(urban == 1) %>% summarise(sum_urban = sum(Area))
jiangsu_area <- merge(sum1, sum2, by = c("Nm_Prfc")) %>% 
  mutate(share_urban = round(sum_urban/sum_area,4)) %>% arrange(share_urban)
jiangsu_area

output <- merge(output, jiangsu_area, by = c("Nm_Prfc"), all.x = TRUE)

jiangsu_highden <- output %>% mutate(high_urban = if_else(share_urban > 0.311,"Land-scarse Prefecture","Land-abundant Prefecture"))
jiangsu_highden <- jiangsu_highden %>% filter(crop_name == "油料", yr > 2010) %>% group_by(yr,high_urban) %>%
  summarise(mean_crop_per_hec = mean(output_per_hec,na.rm = TRUE))
p <- ggplot(data = filter(jiangsu_highden),aes(x = yr, y = mean_crop_per_hec))
p <- p + geom_point() + geom_line() + scale_x_continuous(breaks = 2011:2021, labels = as.character(2011:2021))
p <- p + facet_wrap(.~high_urban) + theme_few()
p <- p + labs(title = "Agricultural output change in the top 1 GDP province", y = "Agricultural output per hectare")
p

crop_name_ls
 crop_name_ls <- output %>% select(crop_name) %>% unique() %>% pull()
 plots <- list()
 for (crop_n in crop_name_ls){

jiangsu_highden <- output %>% mutate(high_urban = if_else(share_urban > 0.311,"Land-scarse Prefecture","Land-abundant Prefecture"))
jiangsu_highden <- jiangsu_highden %>% filter(crop_name == crop_n, yr > 2010) %>% group_by(yr,high_urban) %>%
  summarise(mean_landsize = mean(crop_area,na.rm = TRUE))
 mean <- jiangsu_highden %>% group_by(high_urban) %>% summarise(mean = mean(mean_landsize,na.rm = TRUE))
 jiangsu_highden <- jiangsu_highden %>% mutate(mean_landsize = if_else(high_urban == "Land-scarse Prefecture", mean_landsize - mean$mean[[2]],mean_landsize - mean$mean[[1]]))
p <- ggplot(data = filter(jiangsu_highden),aes(x = yr, y = mean_landsize))
p <- p + geom_point() + geom_line() + scale_x_continuous(breaks = 2011:2021, labels = as.character(2011:2021))
p <- p + facet_wrap(.~high_urban) + theme_few()
p <- p + labs(title = "Cropland size change in the top 1 GDP province", y = "Cropland size of each county")
p
plots[[crop_n]] <- p
}
plots[["棉花"]]

jiangsu_highden <- output %>% mutate(high_urban = if_else(share_urban > 0.311,"Land-scarse Prefecture","Land-abundant Prefecture"))
jiangsu_highden <- jiangsu_highden %>% filter(yr > 2010) %>% group_by(yr,high_urban,county_name) %>%
  summarise(sum_output = sum(output,na.rm = TRUE)) %>% ungroup()
jiangsu_highden <- jiangsu_highden %>% filter(yr > 2010) %>% group_by(yr,high_urban) %>%
  summarise(mean_output = mean(sum_output,na.rm = TRUE))
p <- ggplot(data = filter(jiangsu_highden),aes(x = yr, y = mean_output))
p <- p + geom_point() + geom_line() + scale_x_continuous(breaks = 2011:2021, labels = as.character(2011:2021))
p <- p + facet_wrap(.~high_urban) + theme_few()
p <- p + labs(title = "Agricultural output change in the top 1 GDP province", y = "Agricultural output per hectare")
p


