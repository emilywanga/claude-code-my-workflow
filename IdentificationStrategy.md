Difference-in-difference
RD (running variable: time，e.g.以三中全会作为卡点（没有高频的土地数据，但有高频的环境污染数据（空气污染和河流污染））)

1. 

一个经典的委托代理问题！

Sample：可以局限于耕地指标紧张的省份（见2018土地增减文件）
Treatment unit：土地（grid类型）
Treatment group：（1）用地指标增减政策实施后（2）强激励的（任期即将到期？三中全会之后还是之前？时间待定？怎样的建设项目对市领导提升较大呢？）的（市，待定，市的话需要把standard error cluster到市层面）委书记（3）治下的市域内（下属各县）的（新出现的耕地类型）土地
Control group：（1）用地指标增减政策实施后（2）弱激励的（市，待定）委书记（3）治下的市域内（下属各县）的（新出现的耕地类型）土地  
![alt text](image.png)

Notification:
i: 土地单位
t: 年
c1: 市
c2：县
l1:市级官员
l2:县级官员
Ytc1c2i: 新增耕地面积

Empirical Model:

Ytc1c2i = alpha1_t + alpha2_c2 + alpha3_l1（共线性？） + beta Xtc1c2l1l2i + Ctc1c2l1l2i gamma + epsilon
a. First Stage
Ytc1c2i: i是耕地了/c2的新增耕地面积
Xtc1c2l1l2i：i处于Treatment还是Control Group
///
Staggered DID？Sample是**初始年不是耕地但结束年是耕地的土地**，而土地一旦变为耕地，就不会再变回去，所以Treatment一旦落实了是不会变的（或者说，现实中可能会变，但根据政策，这是耕地保护不到位）
///
并不是Staggered DID，quasi-random experiment更准确

b.
Ytc1c2i: t年c1市c2县（看数据决定是否可以进一步细化）的自然灾害（泥石流，滑坡，盐碱etc）
Xtc1c2l1l2i：i有多大比例是Treatment组的新增耕地
纯OLS（or Probit？）如果灾害的数据点大小（30X30）可以和Treatment对应，那么可以算staggered DID？或者看我们怎么去定义X使其变为dummy了

Identification assumption：处于控制组还是处理组（强弱激励）在控制变量后和不可观测值不相关（随机的）

Hypothesis
![alt text](image-1.png)

## Diff-in-Diff of Protective Index of Farmland

General Idea: 耕地指标出台后，farmland index is binding on urbanization and economic growth for cities with limited undeveloped area (barren).

