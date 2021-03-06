library(reshape2)
library(ggplot2)
require(dplyr)#install.packages("dplyr")
#install.packages("rFSA") 
library(rFSA)


dfJing <- read.table("T://Wellington//Projects A-E//CC-LUS//Point_analysis//Jing//080319//wb_annual_31080.csv", header = TRUE, sep = ",")
#Jing's water balance redone 08/03/19
names(dfJing) <- c("Model","Crop","Sim_Soil","Region","RCP","GCM","Year","J.PCP","J.PET","J.AET","J.PED","J.IC","J.EC", "J.ETC", "J.AEC")
#Metadata Jing:
# PCP: Precipitation 
# PET: Potential Evapotranspiration 
# ETC: Crop Evapotranspiration Under standard condition. This is the FAO's definition of crop evapotranspiration demand. When calculating the evapotranspiration deficit, we compare the actual evapotranspiration with this one rather than the PET. However, for pasture, the ETC = PET, because the Kc = 1.
# EC: Evaporation from canopy. This is the amount of water that we remove from PET (because it's part of PET) before we calculate the ETC. So the ETC = (PET - EC) * Kc
# AEC: Actual Evapotranspiration from Crop and Soil.
# AET:  Actual Evapotranspiration. AET = AEC + EC
# PED: Evapotranspiration Deficit. This is the difference between ETC (demand) and AEC. 

levels(dfJing$RCP) <- c("RCPPa","RCP26","RCP45","RCP60","RCP85")
dfJing$Region <- (as.factor(dfJing$Region))
levels(dfJing$Region) <- "HawkesBay"
dfJingmaize <- dfJing[dfJing$Crop == "maize",]
dfJingmaize <- dfJingmaize %>% select(Sim_Soil,Region,RCP,GCM,Year,J.PCP,J.PET,J.AET,J.PED,   
                                       J.IC,J.EC,J.ETC,J.AEC)


dfAG <- read.table("T://Wellington//Projects A-E//CC-LUS//Point_analysis//SPEI/spei1-3mthAG1986-2120.csv", header = TRUE, sep = ",")
dfAG2 <- read.table("T://Wellington//Projects A-E//CC-LUS//Point_analysis//AG//AGann_allRCP.csv", header = TRUE, sep = ",")

dfAGall <- full_join(dfAG2,dfAG)

str(dfAGall)
dfAGall2 <- aggregate(. ~ RCP  + GCM + Region + Year, dfAGall,mean)
dfAGall2$RCP <- factor(dfAGall2$RCP,levels(dfAGall2$RCP)[c(5,1:4)])

#df3 <- inner_join(df2, dfAG, by = c('RCP','GCM','Year','Region'))
df3 <- inner_join( dfAGall2,dfJingmaize, by = c('RCP','GCM','Year','Region'))
df3$Region <- as.factor(df3$Region)
#Exploring data:
ggplot(aes(y = J.PET, x = Year, color = GCM), data = dfJing) + geom_line()

dfEd <- read.table("T://Wellington//Projects A-E//CC-LUS//Point_analysis//Edmar//P005_CropRotationOLWDS.csv", header = TRUE, sep = ",")

#Separate ERA (not in AG's DB)
#dfEd.era <- dfEd[dfEd$RCP == "era",]

#Try RCP8.5 and past/Waimakariri/Hadley/ rainfed / genotype long (should be short?)
#Question to answer: what is the drought impact on yield (nitrate leaching if we can too)

#dfEd.test <- dfEd[((dfEd$RCP == "rcp8.5" | dfEd$RCP == "rcppast") & dfEd$AGENT_NO == 31080 & dfEd$Fact2 == "rainfed" & dfEd$Fact1 == "long" & dfEd$SoilStamp == "waimakaririds_55b2" & dfEd$GCM == "hadgem2-es"),]
dfEd.test <- dfEd[((dfEd$RCP == "rcp8.5" | dfEd$RCP == "rcppast") & dfEd$AGENT_NO == 31080 & dfEd$Fact2 == "rainfed" & dfEd$Fact1 == "long" & dfEd$SoilStamp == "waimakaririds_55b2" & dfEd$GCM == "gfdl-cm3"),]
ggplot(aes(y = TotalBiomass, x = TimeSlice, fill = CurrentSpecies), data = dfEd.test) + geom_boxplot()
ggplot(aes(y = ETact, x = TimeSlice, fill = CurrentSpecies), data = dfEd.test) + geom_boxplot()
ggplot(aes(y = CRP_eo, x = TimeSlice, fill = CurrentSpecies), data = dfEd.test) + geom_boxplot()

ggplot(dfEd.test, aes(x=year)) + geom_line(aes(y=TotalBiomass, col=CurrentSpecies))


#Look at maize:
dfm <- dfEd.test[(dfEd.test$CurrentCrop == "maize_long"),]
#ggplot(dfm, aes(x=year)) + geom_line(aes(y=TotalBiomass)) #exploring
#ggplot(dfm, aes(x=year)) + geom_line(aes(y=TempCycleAve))
#I don't understand why I have duplicated rows for some years, not others...:
dfm[dfm$year == 2064,]
dfm[dfm$year == 2065,]

dfm2 <- aggregate(. ~ year, dfm,mean)
names(dfm2)[1] <- "Year"

#Check droughtiness:
#dfclm <- dfAGall2[(dfAGall2$Region == "HawkesBay" & dfAGall2$GCM == "HAD"& (dfAGall2$RCP == "RCP85" | dfAGall2$RCP == "RCPPa")),]
dfclm <- df3[(df3$Region == "HawkesBay" & df3$GCM == "GFD"& (df3$RCP == "RCP85" | df3$RCP == "RCPPa")),]
ggplot(dfclm, aes(x=Year)) + geom_line(aes(y=SPEI3.Feb)) #exploring

#joining the 2 DB:
dfmaize <- full_join(dfm2, dfclm, by = c('Year'))
dfmaize.y = dfmaize[order(dfmaize$Year),]

str(dfmaize.y)
cordf <- dfmaize.y[,c(20:ncol(dfmaize.y))]
cordf <- cordf[,-c(59:61)]
cordf<- na.omit(cordf)
cordf$ScaleTB <- scale(cordf$TotalBiomass)
cormat <- round(cor(cordf),2)
head(cormat)
melted_cormat <- melt(cormat)
#ggplot(data = melted_cormat, aes(x=Var1, y=Var2, fill=value)) + geom_tile()
# Get lower triangle of the correlation matrix
get_lower_tri<-function(cormat){
  cormat[upper.tri(cormat)] <- NA
  return(cormat)
}
# Get upper triangle of the correlation matrix
get_upper_tri <- function(cormat){
  cormat[lower.tri(cormat)]<- NA
  return(cormat)
}

upper_tri <- get_upper_tri(cormat)
upper_tri
lower_tri <- get_lower_tri(cormat)
lower_tri


melted_cormat <- melt(upper_tri, na.rm = TRUE)
ggplot(data = melted_cormat, aes(Var2, Var1, fill = value))+
  geom_tile(color = "white")+
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                       midpoint = 0, limit = c(-1,1), space = "Lab", 
                       name="Pearson\nCorrelation") +
  theme_minimal()+ 
  theme(axis.text.x = element_text(angle = 90, vjust = 1, 
                                   size = 5, hjust = 1) ,axis.text.y = element_text(angle = 0, vjust = 1, 
                                                                                    size = 5, hjust = 1) )+
  coord_fixed()

#Looking at the heatmap of correlation:
#Total Biomass linked to SPEI in jan and feb (BUT we need to de-trend this var to get more value)
# SPEI1 and SPEI2 correlated, and SPEI2 and SPEI3 correlated (number of months prior contributing to the calculation)
# or should we use TotalYield, TTsum, or AnthesisTT, or...?

#CRP_eo potential accum PET.
#CRP_es Eccum ET during crop cycle, negative with TotBiomass
#.. Need to investigate this correlation matrix more....

#time series test?
# tsb <- ts(cordf$TotalBiomass)
# tss <- ts(cordf$SPEI3.Jan)
# ccf(tsb,tss) #no lag time so affected by drought on the same year, not previous years
# 
# plot(cbind(tsb,tss))

#TEST ON TOTAL BIOMASS, TIER 1 indicators
#Seems to have some NAs for DG25, DG30, DG35, MaturityTT and FrostDOY
dfall <- cordf %>% select(CRP_eo,CRP_es, CRP_ep,ETact,CRP_drain,CRP_rain,
                            frostDays,frostIntensity, TTsum,AnthesisTT, 
                             wetDays, wetness, DryDays, CRP_swd_frac,
                          J.PCP, J.PET, J.AET, J.PED,  J.IC,  J.EC, J.ETC, J.AEC,
                            Tannual,GDD7annual,
                            Nbfrostdays,Nbhotdays25,Sumchillhrs,SPEI3.Feb, SPEI3.Jan, ScaleTB,TotalBiomass)
names(dfall) <- c("T1.CRP_eo","T2.CRP_es","T3.CRP_ep","T2.ETact","T3.CRP_drain","T1.CRP_rain",
                  "T1.frostDays","T1.frostIntensity","T1.TTsum","T2.AnthesisTT",
                  "T2.wetDays",
                  "T2.wetness","T3.DryDays",
                  "T3.CRP_swd_frac",
                  "T2J.PCP", "T2J.PET","T2J.AET", "T2J.PED","T2J.IC","T2J.EC", "T2J.ETC","T2J.AEC",
                  "T1.Tannual","T1.GDD7annual",
                  "T1.Nbfrostdays","T1.Nbhotdays25","T1.Sumchillhrs",
                  "T1.SPEI3.Feb","T1.SPEI3.Jan","Y.ScaleTB","Y.TB")
cormat2 <- round(cor(dfall),2)
head(cormat2)
lower_tri <- get_lower_tri(cormat2)
melted_cormat <- melt(lower_tri, na.rm = TRUE)
ggplot(data = melted_cormat, aes(Var2, Var1, fill = value))+
  geom_tile(color = "white")+
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                       midpoint = 0, limit = c(-1,1), space = "Lab", 
                       name="Pearson\nCorrelation") +
  theme_minimal()+ 
  theme(axis.text.x = element_text(angle = 90, vjust = 1, 
                                   size = 5, hjust = 1) ,axis.text.y = element_text(angle = 0, vjust = 1, 
                                                                                    size = 5, hjust = 1) )+
  coord_fixed()

#Don't understand the results from Jing:
#PCP negatively correlated to TBiomass
#AET negatively correlated to TBiomass
#PED (lack of water) positively correlated to TBiomass
#J.PET and CRP_eo not strongly correlated??
#ED TO CHECK: I may have binded tables wrongly???


#Interactions with T1 ONLY
dfT1 <- dfall[ , grepl( "T1" , names( dfall)) ]
dfT2 <- dfall[ , grepl( "T2" , names( dfall )) ]
dfT3 <- dfall[ , grepl( "T3" , names( dfall )) ]

testT1 <- cbind(dfT1, dfall$Y.ScaleTB)
names(testT1)[ncol(testT1)] <- "Y.ScaleTB"

library(rFSA)
fsaFit<-FSA(
  formula="Y.ScaleTB ~ .", #Model that you wish to compare new models to. The variable to the left of the '~' will be used as the response variable in all model fits
  data= testT1, #specify dataset 
  fitfunc = lm, #method you wish to use 
  #fixvar = c('wt','cyl'), # variables that should be fixed in every model that is considered 
  m = 2, #order of interaction or subset to consider
  numrs = 10, #number of random starts to do 
  interactions = FALSE, #If TRUE, then the m variables under condsideration will be added to the model with a '*' between them, if FALSE then the m variables will be added to the model with a '+' between them. Basically, do you want to look for interactions or best subsets.
  criterion = adj.r.squared, #Criterion function used to asses model fit
  minmax = "max" #Should Criterion function be minimized ('min') or maximized ('max').
  
)

fsaFit #shows results from running FSA
print(fsaFit) #shows results from running FSA
summary(fsaFit) #shows summary from all models found by FSA
plot(fsaFit) #plots diagnostic plots for all models found by FSA
fitted(fsaFit) #fitted values from all models found by FSA
#At tier 1
#T1.CRP_eo:T1.CRP_rain (with Hadley)
#Total accumulated potential evapotranspiration (PrestleyTaylor)
#Accumulated rainfall during crop cycle
#Y.ScaleTB~T1.SPEI3.Feb+T1.SPEI3.Jan (with GFD)


testT2 <- cbind(dfT1, dfT2, dfall$Y.ScaleTB)
names(testT2)[ncol(testT2)] <- "Y.ScaleTB"
fsaFit<-FSA(
  formula="Y.ScaleTB ~ .", #Model that you wish to compare new models to. The variable to the left of the '~' will be used as the response variable in all model fits
  data= testT2, #specify dataset 
  fitfunc = lm, #method you wish to use 
  #fixvar = c('wt','cyl'), # variables that should be fixed in every model that is considered 
  m = 2, #order of interaction or subset to consider
  numrs = 10, #number of random starts to do 
  interactions = FALSE, #If TRUE, then the m variables under condsideration will be added to the model with a '*' between them, if FALSE then the m variables will be added to the model with a '+' between them. Basically, do you want to look for interactions or best subsets.
  criterion = adj.r.squared, #Criterion function used to asses model fit
  minmax = "max" #Should Criterion function be minimized ('min') or maximized ('max').
  
)

fsaFit #shows results from running FSA
print(fsaFit) #shows results from running FSA
summary(fsaFit) #shows summary from all models found by FSA
plot(fsaFit) #plots diagnostic plots for all models found by FSA
fitted(fsaFit) #fitted values from all models found by FSA
#At tier 2 (with or without interaction)
# Y.ScaleTB~T2.CRP_es+T2.ETact
#Accumulated evaporation during crop cycle
#Actual ET sum

testT3 <- cbind(dfT1, dfT2, dfT3,dfall$Y.ScaleTB)
names(testT3)[ncol(testT3)] <- "Y.ScaleTB"

fsaFit<-FSA(
  formula="Y.ScaleTB ~ .", #Model that you wish to compare new models to. The variable to the left of the '~' will be used as the response variable in all model fits
  data= testT3, #specify dataset 
  fitfunc = lm, #method you wish to use 
  #fixvar = c('wt','cyl'), # variables that should be fixed in every model that is considered 
  m = 2, #order of interaction or subset to consider
  numrs = 10, #number of random starts to do 
  interactions = FALSE, #If TRUE, then the m variables under condsideration will be added to the model with a '*' between them, if FALSE then the m variables will be added to the model with a '+' between them. Basically, do you want to look for interactions or best subsets.
  criterion = adj.r.squared, #Criterion function used to asses model fit
  minmax = "max" #Should Criterion function be minimized ('min') or maximized ('max').
  
)
fsaFit #shows results from running FSA
print(fsaFit) #shows results from running FSA
summary(fsaFit) #shows summary from all models found by FSA
plot(fsaFit) #plots diagnostic plots for all models found by FSA
fitted(fsaFit) #fitted values from all models found by FSA

#At Tier 3:
#Y.ScaleTB~T3.CRP_ep+T3.CRP_swd_frac
#Accumulated plant transpiration during crop cycle
#Soil water deficit index (demand - supply)


#Test with unscaled TB
testT1 <- cbind(dfT1, dfall$Y.TB)
names(testT1)[ncol(testT1)] <- "Y.TB"

fsaFit<-FSA(
  formula="Y.TB ~ .", #Model that you wish to compare new models to. The variable to the left of the '~' will be used as the response variable in all model fits
  data= testT1, #specify dataset 
  fitfunc = lm, #method you wish to use 
  #fixvar = c('wt','cyl'), # variables that should be fixed in every model that is considered 
  m = 2, #order of interaction or subset to consider
  numrs = 10, #number of random starts to do 
  interactions = FALSE, #If TRUE, then the m variables under condsideration will be added to the model with a '*' between them, if FALSE then the m variables will be added to the model with a '+' between them. Basically, do you want to look for interactions or best subsets.
  criterion = adj.r.squared, #Criterion function used to asses model fit
  minmax = "max" #Should Criterion function be minimized ('min') or maximized ('max').
  
)

fsaFit #shows results from running FSA
print(fsaFit) #shows results from running FSA
summary(fsaFit) #shows summary from all models found by FSA
plot(fsaFit) #plots diagnostic plots for all models found by FSA
fitted(fsaFit) #fitted values from all models found by FSA
#At tier 1
#T1.CRP_eo:T1.CRP_rain (with Hadley)
#Total accumulated potential evapotranspiration (PrestleyTaylor)
#Accumulated rainfall during crop cycle
#Y.TB~T1.SPEI3.Feb+T1.SPEI3.Jan (with GFD)


testT2 <- cbind(dfT1, dfT2, dfall$Y.TB)
names(testT2)[ncol(testT2)] <- "Y.TB"
fsaFit<-FSA(
  formula="Y.TB ~ .", #Model that you wish to compare new models to. The variable to the left of the '~' will be used as the response variable in all model fits
  data= testT2, #specify dataset 
  fitfunc = lm, #method you wish to use 
  #fixvar = c('wt','cyl'), # variables that should be fixed in every model that is considered 
  m = 2, #order of interaction or subset to consider
  numrs = 10, #number of random starts to do 
  interactions = FALSE, #If TRUE, then the m variables under condsideration will be added to the model with a '*' between them, if FALSE then the m variables will be added to the model with a '+' between them. Basically, do you want to look for interactions or best subsets.
  criterion = adj.r.squared, #Criterion function used to asses model fit
  minmax = "max" #Should Criterion function be minimized ('min') or maximized ('max').
  
)

fsaFit #shows results from running FSA
print(fsaFit) #shows results from running FSA
summary(fsaFit) #shows summary from all models found by FSA
plot(fsaFit) #plots diagnostic plots for all models found by FSA
fitted(fsaFit) #fitted values from all models found by FSA
#At tier 2 (with or without interaction)
# Y.TB~T2.CRP_es+T2.ETact
#Accumulated evaporation during crop cycle
#Actual ET sum

testT3 <- cbind(dfT1, dfT2, dfT3,dfall$Y.TB)
names(testT3)[ncol(testT3)] <- "Y.TB"

fsaFit<-FSA(
  formula="Y.TB ~ .", #Model that you wish to compare new models to. The variable to the left of the '~' will be used as the response variable in all model fits
  data= testT3, #specify dataset 
  fitfunc = lm, #method you wish to use 
  #fixvar = c('wt','cyl'), # variables that should be fixed in every model that is considered 
  m = 2, #order of interaction or subset to consider
  numrs = 10, #number of random starts to do 
  interactions = FALSE, #If TRUE, then the m variables under condsideration will be added to the model with a '*' between them, if FALSE then the m variables will be added to the model with a '+' between them. Basically, do you want to look for interactions or best subsets.
  criterion = adj.r.squared, #Criterion function used to asses model fit
  minmax = "max" #Should Criterion function be minimized ('min') or maximized ('max').
  
)
fsaFit #shows results from running FSA
print(fsaFit) #shows results from running FSA
summary(fsaFit) #shows summary from all models found by FSA
plot(fsaFit) #plots diagnostic plots for all models found by FSA
fitted(fsaFit) #fitted values from all models found by FSA

#At Tier 3:
#Y.TB~T3.CRP_ep+T3.CRP_swd_frac
#Accumulated plant transpiration during crop cycle
#Soil water deficit index (demand - supply)

