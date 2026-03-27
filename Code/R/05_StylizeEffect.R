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
library(fixest)
library(ggthemes)

aggre <- read_excel("../LandProtection/data/aggregate_crop.xlsx")
aggre$urban <- ifelse(grepl("区$",aggre$Nm_Cnty),1,0) 
aggre <- aggre %>% rename(c_sum = "_sum")
# print(aggre %>% filter(urban == 0) %>% distinct(Nm_Cnty),n=53)

aggre_byyr_u <- aggre %>% filter(urban == 1) %>% 
  group_by(yr) %>% summarise(mean_crop = mean(c_sum))
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

jiangsu_u <- jiangsu %>% filter(urban == 1) %>% group_by(yr) %>%
  summarise(mean_crop = mean(MEAN,na.rm = TRUE))
p <- ggplot(data = filter(jiangsu_u),aes(x = yr, y = mean_crop))
p <- p + geom_point() + geom_line() + 
  scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
p

jiangsu_r <- jiangsu %>% filter(urban == 0) %>% group_by(yr) %>%
  summarise(mean_crop = mean(MEAN,na.rm = TRUE))
p <- ggplot(data = filter(jiangsu_r),aes(x = yr, y = mean_crop))
p <- p + geom_point() + geom_line() + 
  scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
p

jiangsu_u <- jiangsu %>% filter(urban == 1, Nm_Prfc == "苏州市") %>% 
  group_by(yr) %>% summarise(mean_crop = mean(MEAN,na.rm = TRUE))
p <- ggplot(data = filter(jiangsu_u),aes(x = yr, y = mean_crop))
p <- p + geom_point() + geom_line() + 
  scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
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


##Filter the unchanged grids out (Not a good idea, rather I demean the plot later to emphasize the change as opposed to the level)
jiangsu_var <- jiangsu %>% group_by(FID) %>% 
  summarise(var_crop = var(MEAN,na.rm=TRUE))
jiangsu_change <- merge(jiangsu,jiangsu_var, by = c("FID"))
jiangsu_change <- jiangsu_change
# jiangsu_change <- jiangsu_change %>% filter(var_crop > 0.0008)
jiangsu_highden <- jiangsu_change %>% 
  filter(mean_density > 0.1) %>% mutate(high_urban = if_else(share_urban>0.5,1,0))

### I have demeaned the outcome
##Coooool
jiangsu_u <- jiangsu_highden %>% filter(urban == 1) %>%
  group_by(yr,high_urban) %>% summarise(mean_crop = mean(MEAN,na.rm = TRUE))
mean <- jiangsu_u %>% group_by(high_urban) %>%
  summarise(mean = mean(mean_crop))
jiangsu_u <- jiangsu_u %>% 
  mutate(mean_crop = if_else(high_urban == 1, mean_crop - mean$mean[[2]],mean_crop - mean$mean[[1]]))
p <- ggplot(data = filter(jiangsu_u),aes(x = yr, y = mean_crop))
p <- p + geom_point() + geom_line() + 
  scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
p <- p+ facet_wrap(.~high_urban)
p


##Not a good idea to add CI here, large variation (You haven't controlled anything!)
# jiangsu_r <- jiangsu_highden %>% filter(urban == 0) %>% group_by(yr,high_urban) %>% 
#   summarise(mean_crop = mean(MEAN,na.rm = TRUE),
#             se = sd(MEAN,na.rm = TRUE)/sqrt(n()),
#             lower_ci = mean_crop - qt(0.975, df=n()-1) * se,
#             upper_ci = mean_crop + qt(0.975, df=n()-1) * se)

##Coooool
jiangsu_r <- jiangsu_highden %>% filter(urban == 0) %>%
  group_by(yr,high_urban) %>% summarise(mean_crop = mean(MEAN,na.rm = TRUE))
mean <- jiangsu_r %>% group_by(high_urban) %>% 
  summarise(mean = mean(mean_crop))
jiangsu_r <- jiangsu_r %>% 
  mutate(mean_crop = if_else(high_urban == 1, mean_crop - mean$mean[[2]],mean_crop - mean$mean[[1]]))
p <- ggplot(data = filter(jiangsu_r),aes(x = yr, y = mean_crop))
p <- p + geom_point() + geom_line() + 
  scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
p <- p+ facet_wrap(.~high_urban)
p


jiangsu_lowurban <- jiangsu_change %>% filter(share_urban < 0.5) %>% mutate(highden = if_else(mean_density > 1100, 1, 0))
jiangsu_r <- jiangsu_lowurban %>% filter(urban == 0) %>% group_by(yr,highden) %>% summarise(mean_crop = mean(MEAN,na.rm = TRUE))
mean <- jiangsu_r %>% group_by(highden) %>% summarise(mean = mean(mean_crop))
jiangsu_r <- jiangsu_r %>% mutate(mean_crop = if_else(highden == 1, mean_crop - mean$mean[[2]],mean_crop - mean$mean[[1]]))
p <- ggplot(data = filter(jiangsu_r),aes(x = yr, y = mean_crop))
p <- p + geom_point() + geom_line() + scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
p <- p+ facet_wrap(.~highden)
p

##Overall
jiangsu_highden <- jiangsu_change %>% mutate(high_urban = if_else(share_urban>0.311,"Prefecture: urban share > mean","Prefecture: urban share < mean"))
jiangsu_u <- jiangsu_highden %>% group_by(yr,high_urban) %>% summarise(mean_crop = mean(MEAN,na.rm = TRUE))
mean <- jiangsu_u %>% group_by(high_urban) %>% summarise(mean = mean(mean_crop))
jiangsu_u <- jiangsu_u %>% mutate(mean_crop = if_else(high_urban == "Prefecture: urban share > mean", mean_crop - mean$mean[[2]],mean_crop - mean$mean[[1]]))
p <- ggplot(data = filter(jiangsu_u),aes(x = yr, y = mean_crop))
p <- p + geom_point() + geom_line() + scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
p <- p + facet_wrap(.~high_urban) + theme_few()
p <- p + labs(title = "Cropland change in Jiangsu province", y = "Cropland share per 3km X 3km grid (Demeaned)")
p

jiangsu_highden <- jiangsu_change %>% mutate(high_density = if_else(Density > 853,"Prefecture: urban density > mean","Prefecture: urban density < mean"))
jiangsu_u <- jiangsu_highden %>% group_by(yr,high_density) %>% summarise(mean_crop = mean(MEAN,na.rm = TRUE))
mean <- jiangsu_u %>% group_by(high_density) %>% summarise(mean = mean(mean_crop))
jiangsu_u <- jiangsu_u %>% mutate(mean_crop = if_else(high_density == "Prefecture: urban density > mean", mean_crop - mean$mean[[2]],mean_crop - mean$mean[[1]]))
p <- ggplot(data = filter(jiangsu_u),aes(x = yr, y = mean_crop))
p <- p + geom_point() + geom_line() + scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
p <- p + facet_wrap(.~high_density) + theme_few()
p <- p + labs(title = "Cropland change in Jiangsu province", y = "Cropland share per 3km X 3km grid (Demeaned)")
p

jiangsu_highden <- jiangsu_change %>% filter(urban == 1) %>% mutate(high_density = if_else(Density > 853,"Prefecture: urban density > mean","Prefecture: urban density < mean"))
jiangsu_u <- jiangsu_highden %>% group_by(yr,high_density) %>% summarise(mean_crop = mean(MEAN,na.rm = TRUE))
mean <- jiangsu_u %>% group_by(high_density) %>% summarise(mean = mean(mean_crop))
jiangsu_u <- jiangsu_u %>% mutate(mean_crop = if_else(high_density == "Prefecture: urban density > mean", mean_crop - mean$mean[[2]],mean_crop - mean$mean[[1]]))
p <- ggplot(data = filter(jiangsu_u),aes(x = yr, y = mean_crop))
p <- p + geom_point() + geom_line() + scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
p <- p + facet_wrap(.~high_density) + theme_few()
p <- p + labs(title = "Cropland change in Jiangsu province", y = "Cropland share per 3km X 3km grid (Demeaned)")
p



##Zhejiang
### Haven't demeaned
zhejiang_mdensity <- aggre %>% filter(urban == 1) %>% group_by(Nm_Prfc) %>% summarise(mean_density = mean(Density)) %>% arrange(mean_density)
sum1 <- aggre %>% group_by(Nm_Prfc) %>% summarise(sum_area = sum(Area))
sum2 <- aggre %>% group_by(Nm_Prfc) %>% filter(urban == 1) %>% summarise(sum_urban = sum(Area))
zhejiang_area <- merge(sum1, sum2, by = c("Nm_Prfc")) %>% mutate(share_urban = round(sum_urban/sum_area,4)) %>% arrange(share_urban)
zhejiang_area
zhejiang_mdensity

zhejiang <- merge(aggre, zhejiang_area, by = c("Nm_Prfc"), all.x = TRUE)
zhejiang <- merge(zhejiang, zhejiang_mdensity, by = c("Nm_Prfc"), all.x = TRUE)

##Filter the unchanged grids out (Better to filter based on whether the grid is of high altitude or impervious central urban area. Variance is also endogenous)
zhejiang_var <- zhejiang %>% group_by(fid) %>% summarise(var_crop = var(c_sum,na.rm=TRUE)) %>% 
  mutate(var_crop = if_else(is.na(var_crop),0.01,var_crop))
skim(zhejiang_var$var_crop)
zhejiang_change <- merge(zhejiang,zhejiang_var, by = c("fid"))
zhejiang_change <- zhejiang_change %>% filter(var_crop > 5)
zhejiang_highden <- zhejiang_change %>% filter(mean_density > 1000) %>% mutate(high_urban = if_else(share_urban>0,1,0))


zhejiang_u <- zhejiang_highden %>% filter(urban == 1) %>% group_by(yr,high_urban) %>% summarise(mean_crop = mean(c_sum,na.rm = TRUE))
p <- ggplot(data = filter(zhejiang_u),aes(x = yr, y = mean_crop))
p <- p + geom_point() + geom_line() + scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
p <- p+ facet_wrap(.~high_urban)
p

##Cooool
zhejiang_r <- zhejiang_highden %>% filter(urban == 0) %>% group_by(yr,high_urban) %>% summarise(mean_crop = mean(c_sum,na.rm = TRUE))
p <- ggplot(data = filter(zhejiang_r),aes(x = yr, y = mean_crop))
p <- p + geom_point() + geom_line() + scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
p <- p+ facet_wrap(.~high_urban)
p


zhejiang_r <- zhejiang_change %>% mutate(highden = if_else(mean_density > 1000, 1, 0))
zhejiang_r <- zhejiang_r %>% filter(urban == 0) %>% group_by(yr,highden) %>%
  summarise(mean_crop = mean(c_sum,na.rm = TRUE))
p <- ggplot(data = filter(zhejiang_r),aes(x = yr, y = mean_crop))
p <- p + geom_point() + geom_line() + scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
p <- p + facet_wrap(.~highden)
p

## Descriptive analysis
names(jiangsu)
jiangsu_22 <- jiangsu %>% filter(yr == 2022)
jiangsu_17 <- jiangsu %>% filter(yr == 2017) %>% select("FID","MEAN") %>%
  rename(MEAN_17 = MEAN)
jiangsu_2217 <- merge(jiangsu_22, jiangsu_17, by = c("FID"))
jiangsu_2217 <- jiangsu_2217 %>% mutate(change_crop_2217 = MEAN - MEAN_17)

# 用prefecture均值看更直观
# jiangsu_m2217change <- jiangsu_2217 %>% group_by(Nm_Cnty) %>% summarise(mchange_crop_2217 = mean(change_crop_2217,na.rm = TRUE) )
# jiangsu_countyinfo <- jiangsu %>% select(Nm_Prfc,Nm_Cnty,urban,Area,Density,share_urban,mean_density) %>% distinct()
jiangsu_m2217change <- jiangsu_2217 %>% group_by(Nm_Prfc,urban) %>% summarise(mchange_crop_2217 = mean(change_crop_2217,na.rm = TRUE) )
jiangsu_countyinfo <- jiangsu %>% select(Nm_Prfc,Area,Density,urban,share_urban,mean_density) %>% distinct()
jiangsu_m2217change <- merge(jiangsu_m2217change,jiangsu_countyinfo,by = c("Nm_Prfc","urban"))
jiangsu_m2217change <- jiangsu_m2217change %>% mutate(sign_change2217 = if_else(mchange_crop_2217>0, "Positive","Negative"))


p <- ggplot(filter(jiangsu_m2217change,urban == 1), aes(x = mean_density, y = share_urban, color = sign_change2217, size = mchange_crop_2217)) +
  geom_point() + 
  scale_color_manual(values = c("Positive" = "blue", "Negative" = "red")) +
  labs(x = "Urban Density (per sq km)",
       y = "Urban Share (%)",
       title = "Cropland Share in urban districts: Comparing 2017 and 2022",
       color = "Change in Cropland Share (sign)",
       size = "Change in Cropland Share (size)") +
  theme_minimal() +
  theme(legend.position = "right")
p



p <- ggplot(filter(jiangsu_m2217change, urban == 0), aes(x = mean_density, y = share_urban, size = mchange_crop_2217, color = sign_change2217)) +
  geom_point() + 
  scale_color_manual(values = c("Positive" = "blue", "Negative" = "red")) +
  labs(x = "Urban Density (per sq km)",
       y = "Urban Share (%)",
       title = "Cropland Share in rural districts: Comparing 2017 and 2022",
       color = "Change in Cropland Share (sign)",
       size = "Change in Cropland Share (size)") +
  theme_minimal() +
  theme(legend.position = "right")
p








names(jiangsu)
jiangsu_reg <- jiangsu %>% mutate(Treatment = if_else(yr > 2017 & share_urban > 0.5,1,0))
formula <- as.formula(paste( "MEAN ~ Treatment |yr + Nm_Cnty"))
lm <- jiangsu_reg %>% 
  filter(urban == 1, mean_density > 1110) %>%
  feols(formula, data = ., cluster = ~ Nm_Cnty)
summary(lm)

jiangsu_reg <- jiangsu %>% mutate(Treatment = if_else(yr > 2017 & share_urban > 0.5,1,0))
formula <- as.formula(paste( "MEAN ~ Treatment |yr + Nm_Cnty"))
lm <- jiangsu_reg %>% 
  filter(urban == 0, mean_density > 1110) %>%
  feols(formula, data = ., cluster = ~ Nm_Cnty)
summary(lm)

jiangsu_reg <- jiangsu %>% mutate(Treatment = if_else(yr > 2017 & share_urban > 0.5,1,0))
formula <- as.formula(paste( "MEAN ~ Treatment |yr + Nm_Cnty"))
lm <- jiangsu_reg %>% 
  filter(urban == 0) %>%
  feols(formula, data = ., cluster = ~ Nm_Cnty)
summary(lm)


##Event Study
years <- jiangsu %>% distinct(yr) %>% arrange(yr) %>% pull()
for (i in years) {
  column_name <- paste("T", i, sep = "")
  jiangsu <- jiangsu %>% mutate(!!sym(column_name) := if_else(yr == i & share_urban > 0.311,1, 0))
}
formula <- as.formula(paste( "MEAN ~ ", paste0(paste("T",years[1:6],sep = ""),collapse = "+"), "+", paste0(paste("T",years[8:12],sep = ""),collapse = "+"),  "|yr + Cd_Cnty"))
lm <- jiangsu  %>%
  feols(formula, data = ., cluster = ~ Cd_Prfc)
summary(lm)
coefplot(list(lm),main = "Effect on cropland share per grid (T = 1{urban share > mean})")

years <- jiangsu %>% distinct(yr) %>% arrange(yr) %>% pull()
for (i in years) {
  column_name <- paste("T", i, sep = "")
  jiangsu <- jiangsu %>% mutate(!!sym(column_name) := if_else(yr == i, share_urban, 0))
}
formula <- as.formula(paste( "MEAN ~ ", paste0(paste("T",years[1:6],sep = ""),collapse = "+"), "+", paste0(paste("T",years[8:12],sep = ""),collapse = "+"),  "|yr + Cd_Cnty"))
lm <- jiangsu  %>%
  feols(formula, data = ., cluster = ~ Cd_Prfc)
summary(lm)
coefplot(list(lm),main = "Effect on cropland share per grid (T = urban share)")


jiangsu_highden <- jiangsu_change %>% mutate(high_urban = if_else(share_urban>0.311,"Land-scarse Prefecture","Land-abundant Prefecture"))
jiangsu_u <- jiangsu_highden %>% group_by(yr,high_urban) %>% summarise(mean_crop = mean(MEAN,na.rm = TRUE))
mean <- jiangsu_u %>% group_by(high_urban) %>% summarise(mean = mean(mean_crop))
jiangsu_u <- jiangsu_u %>% mutate(mean_crop = if_else(high_urban == "Land-scarse Prefecture", mean_crop - mean$mean[[2]],mean_crop - mean$mean[[1]]))
p <- ggplot(data = filter(jiangsu_u),aes(x = yr, y = mean_crop))
p <- p + geom_point() + geom_line() + scale_x_continuous(breaks = 2011:2022, labels = as.character(2011:2022))
p <- p + facet_wrap(.~high_urban) + theme_few()
p <- p + labs(title = "Cropland change in the top 1 GDP province", y = "Cropland share per 3km X 3km grid (Demeaned)")
p
