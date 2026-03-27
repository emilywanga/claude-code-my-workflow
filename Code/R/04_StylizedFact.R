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

aggre <- read_excel("../LandProtection/data/aggregate_crop.xlsx")
aggre$urban <- ifelse(grepl("区$",aggre$Nm_Cnty),1,0) 
aggre <- aggre %>% rename(c_sum = "_sum")
# print(aggre %>% filter(urban == 0) %>% distinct(Nm_Cnty),n=53)

aggre_byyr_u <- aggre %>% filter(urban == 1) %>% group_by(yr) %>% summarise(mean_crop = mean(c_sum))
p_u <- ggplot(data = filter(aggre_byyr_u),aes(x = yr, y = mean_crop))
p_u <- p_u + geom_point() + geom_line() + scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
p_u

aggre_byyr <- aggre %>% filter(urban == 0) %>% group_by(yr) %>% summarise(mean_crop = mean(c_sum))
p <- ggplot(data = filter(aggre_byyr),aes(x = yr, y = mean_crop))
p <- p + geom_point() + geom_line() + scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
p

# aggre_byyr_ct <- aggre %>% filter(urban == 1) %>% group_by(yr,Nm_Prfc) %>% summarise(mean_crop = mean(c_sum))
# p <- ggplot(data = filter(aggre_byyr_ct),aes(x = yr, y = mean_crop)) + facet_wrap(.~Nm_Prfc)
# p <- p + geom_point() + geom_line() + scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
# p

aggre_byyr_u <- aggre %>% filter(urban == 1 & Nm_Prfc== "杭州市") %>% group_by(yr) %>% summarise(mean_crop = mean(c_sum))
p_u <- ggplot(data = filter(aggre_byyr_u),aes(x = yr, y = mean_crop))
p_u <- p_u + geom_point() + geom_line() + scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
p_u

aggre_byyr_u <- aggre %>% filter(urban == 0 & Nm_Prfc== "杭州市") %>% group_by(yr) %>% summarise(mean_crop = mean(c_sum))
p_u <- ggplot(data = filter(aggre_byyr_u),aes(x = yr, y = mean_crop))
p_u <- p_u + geom_point() + geom_line() + scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
p_u

aggre_byyr_u <- aggre %>% filter(urban == 1 & Nm_Prfc== "宁波市") %>% group_by(yr) %>% summarise(mean_crop = mean(c_sum))
p_u <- ggplot(data = filter(aggre_byyr_u),aes(x = yr, y = mean_crop))
p_u <- p_u + geom_point() + geom_line() + scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
p_u

aggre_byyr_u <- aggre %>% filter(urban == 0 & Nm_Prfc== "宁波市") %>% group_by(yr) %>% summarise(mean_crop = mean(c_sum))
p_u <- ggplot(data = filter(aggre_byyr_u),aes(x = yr, y = mean_crop))
p_u <- p_u + geom_point() + geom_line() + scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
p_u

## Jiangsu
provinf <- read_excel("../LandProtection/data/Jiangsu/Grid_3km_allinfo.xls")
mean11 <- read_excel("../LandProtection/data/Jiangsu/mean11.xls")
mean12 <- read_excel("../LandProtection/data/Jiangsu/mean12.xls")
mean13 <- read_excel("../LandProtection/data/Jiangsu/mean13.xls")
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

jiangsu_u <- jiangsu %>% filter(urban == 1) %>% group_by(yr) %>% summarise(mean_crop = mean(MEAN,na.rm = TRUE))
p <- ggplot(data = filter(jiangsu_u),aes(x = yr, y = mean_crop))
p <- p + geom_point() + geom_line() + scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
p

jiangsu_r <- jiangsu %>% filter(urban == 0) %>% group_by(yr) %>% summarise(mean_crop = mean(MEAN,na.rm = TRUE))
p <- ggplot(data = filter(jiangsu_r),aes(x = yr, y = mean_crop))
p <- p + geom_point() + geom_line() + scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
p

jiangsu_u <- jiangsu %>% filter(urban == 1, Nm_Prfc == "苏州市") %>% group_by(yr) %>% summarise(mean_crop = mean(MEAN,na.rm = TRUE))
p <- ggplot(data = filter(jiangsu_u),aes(x = yr, y = mean_crop))
p <- p + geom_point() + geom_line() + scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
p

jiangsu_r <- jiangsu %>% filter(urban == 0, Nm_Prfc == "苏州市") %>% group_by(yr) %>% summarise(mean_crop = mean(MEAN,na.rm = TRUE))
p <- ggplot(data = filter(jiangsu_r),aes(x = yr, y = mean_crop))
p <- p + geom_point() + geom_line() + scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
p

jiangsu_u <- jiangsu %>% filter(urban == 1, Nm_Prfc == "南京市") %>% group_by(yr) %>% summarise(mean_crop = mean(MEAN,na.rm = TRUE))
p <- ggplot(data = filter(jiangsu_u),aes(x = yr, y = mean_crop))
p <- p + geom_point() + geom_line() + scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
p

jiangsu_r <- jiangsu %>% filter(urban == 0, Nm_Prfc == "南京市") %>% group_by(yr) %>% summarise(mean_crop = mean(MEAN,na.rm = TRUE))
p <- ggplot(data = filter(jiangsu_r),aes(x = yr, y = mean_crop))
p <- p + geom_point() + geom_line() + scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
p

jiangsu_u <- jiangsu %>% filter(urban == 1, Nm_Prfc == "无锡市") %>% group_by(yr) %>% summarise(mean_crop = mean(MEAN,na.rm = TRUE))
p <- ggplot(data = filter(jiangsu_u),aes(x = yr, y = mean_crop))
p <- p + geom_point() + geom_line() + scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
p

jiangsu_r <- jiangsu %>% filter(urban == 0, Nm_Prfc == "无锡市") %>% group_by(yr) %>% summarise(mean_crop = mean(MEAN,na.rm = TRUE))
p <- ggplot(data = filter(jiangsu_r),aes(x = yr, y = mean_crop))
p <- p + geom_point() + geom_line() + scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
p

jiangsu %>% filter(urban == 1) %>% group_by(Nm_Prfc) %>% summarise(mean_density = mean(Densigy))




