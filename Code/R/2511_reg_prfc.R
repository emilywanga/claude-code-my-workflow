pacman::p_load(dplyr, ggplot2, tidyverse,fixest,readxl,data.table)

# Load data
setwd("/Users/wangze/Dropbox/Emi/Land_Project_wtichcc")
cropland <- read.csv("../LandProtection/data/Jiangsu/jiangsu_crop_ready.csv")
index <- read_excel("Data/processed/jiangsu_land_index/Land_Index.xlsx",sheet = 7)

df <- fig

# 1. 计算线性映射参数：freq -> quotacut 区间
q_min <- min(df$quotacut, na.rm = TRUE)
q_max <- max(df$quotacut, na.rm = TRUE)
f_min <- min(df$mentionedpressure_freq, na.rm = TRUE)
f_max <- max(df$mentionedpressure_freq, na.rm = TRUE)

b <- (q_max - q_min) / (f_max - f_min)
a <- q_min - b * f_min   # 使 freq = f_min 时，对应 q_min

# 2. 生成右轴用的 scaled 变量
df$freq_scaled <- a + b * df$mentionedpressure_freq

# 3. 画图：左轴 = quotacut；右轴 = mentionedpressure_freq（通过 freq_scaled 映射）
ggplot(df, aes(x = urban_share)) +
  # 左轴：指标下调幅度
  geom_point(aes(y = quotacut, color = "Quota Cut"), size = 3, alpha = 0.8) +
  geom_smooth(aes(y = quotacut, color = "Quota Cut"),
              method = "lm", se = FALSE, size = 1.1) +
  
  # 右轴：被提及次数（用 freq_scaled）
  geom_point(aes(y = freq_scaled, color = "Mention Frequency"),
             size = 3, alpha = 0.8, shape = 17) +
  geom_smooth(aes(y = freq_scaled, color = "Mention Frequency"),
              method = "lm", se = FALSE, size = 1.1, linetype = "dashed") +
  
  scale_color_manual(values = c(
    "Quota Cut" = "#1f77b4",
    "Mention Frequency" = "#ff7f0e"
  )) +
  
  scale_y_continuous(
    name = "Quota Cut (negative = stricter)",
    sec.axis = sec_axis(
      # 反变换：y -> freq
      ~ (. - a) / b,
      name = "Frequency Mentioned in Documents"
    )
  ) +
  
  labs(
    x = "Urban Administrative Share (district share)",
    title = "Urban Share and Two Dimensions of Land Protection Pressure",
    color = ""
  ) +
  theme_minimal(base_size = 15) +
  theme(
    legend.position = "top",
    legend.title = element_blank()
  )

