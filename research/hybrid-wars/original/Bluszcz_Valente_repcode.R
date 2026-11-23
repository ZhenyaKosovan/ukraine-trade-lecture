require(Synth)
require(ggplot2)
require(reshape2)

source('Bluszcz_Valente_auxiliary_fx.R')

countries <- read.csv2("Bluszcz_Valente_repdata_countries.csv")

#####################################################################
######################                     ##########################
###################### Data preprocessing  ##########################
######################                     ##########################
#####################################################################

countries$Country <- as.character(countries$Country)
countries$HDI <- as.numeric(as.character(countries$HDI))

#Add new variables regarding trade with Russia
countries$export_russia_share_GDP = countries$Import_Russia * 1000 / countries$GDP_current_US
countries$import_russia_share_GDP = countries$Export_Russia * 1000 / countries$GDP_current_US

countries$export_russia_share_export = countries$export_russia_share_GDP * 100 / countries$Exports_goods
countries$import_russia_share_import = countries$import_russia_share_GDP * 100 / countries$Imports_goods

countries$russia_trade_dependence = countries$export_russia_share_GDP + countries$import_russia_share_GDP

#####################################################################
####################      Common support     ########################
#####################################################################

data_box = countries[, c('Year', 'Country', 'russia_trade_dependence', 'HDI', 'Polity', 'Inflation_prices', 'GFCF', 'GDP_2011')]
colnames(data_box) = c('Year', "Unit", 'TradeDep', "HDI", 'Polity', 'Inflation', 'GFCF', 'GCPpc')

variable_names <- c('TradeDep', "HDI", 'Polity', 'Inflation', 'GFCF', 'GCPpc')
cnames <- c("dummy",
            name=expression(italic("TradeDep")),
            name=expression(italic("HDI")), 
            name=expression(italic("Polity")),
            name=expression(italic("Inflation")),
            name=expression(italic("GFCF")),
            name=expression(italic("GCPpc"))
)

variable_column_numbers <- match(variable_names,names(data_box))

# Add a dummy for which city is used
data_box$treated = ifelse(data_box$Unit == 'Ukraine', 'Ukraine', "Control sample")

X <- cbind(data_box$treated,data_box[,variable_column_numbers])
X$TradeDep = demean_fn(X$TradeDep)
X$HDI = demean_fn(X$HDI)
X$Polity = demean_fn(X$Polity)
X$Inflation = demean_fn(X$Inflation)
X$GFCF = demean_fn(X$GFCF)
X$GCPpc = demean_fn(X$GCPpc)

X <- X[complete.cases(X),] # eliminate nas
dim(X) # no much loss
str(X)

# Run boxplot
bp_descriptives_function(X=X, cnames, colorful = TRUE, ylimseq=seq(-2,3,1))

#####################################################################
######################                     ##########################
###################### Country level SCM   ##########################
######################                     ##########################
#####################################################################

par(mfrow=c(1,1))

syn <- dataprep(
  foo = countries, 
  predictors = c('russia_trade_dependence', 'HDI', 'Polity', 'Inflation_prices', 'GFCF'), 
  special.predictors = list(
    list('GDP_2011', 2000, "mean"),
    list('GDP_2011', 2012, "mean")),
  dependent = "GDP_2011", 
  unit.variable = "Id",
  time.variable = "Year",
  controls.identifier = c(1:17),
  treatment.identifier = 18, 
  time.predictors.prior = c(1995:2012),
  time.optimize.ssr = c(1995:2012), 
  time.plot = c(1995:2017),
  unit.names.variable = 'Country')

#Perform the optimization procedure
synth.out <- synth(syn)

#Show the results of SCM
synth.tables <- synth.tab(
  dataprep.res = syn,
  synth.res = synth.out)
print(synth.tables)

#Differences in GDP between Ukraine and synthetic unit
syn$Y1plot - (syn$Y0plot %*% synth.out$solution.w)

path.plot(dataprep.res = syn, synth.res = synth.out, Legend.position=c("topleft"), Ylab = 'per capita GDP, 2011 international dollars (PPP)')
abline(v=2012)

gaps.plot(dataprep.res = syn, synth.res = synth.out, Ylab = 'Prediction Error')
abline(v=2012)

alpha1t <- (syn$Y1plot - (syn$Y0plot %*% synth.out$solution.w))[19:23]
alpha1 <- mean(alpha1t)
alpha1

#####################################################################
#####################################################################
########################   Placebo Tests   ##########################
#####################################################################
#####################################################################

store <- matrix(NA,length(1995:2017),17)
colnames(store) <- unique(countries$Country)[-18]

# run placebo test
for(iter in 1:17)
{
  dataprep.out <-
    syn <- dataprep(
      foo = countries, 
      predictors = c('russia_trade_dependence', 'HDI', 'Polity', 'Inflation_prices', 'GFCF'), 
      special.predictors = list(
        list('GDP_2011', 2000, "mean"),
        list('GDP_2011', 2012, "mean")),
      dependent = "GDP_2011", 
      unit.variable = "Id",
      time.variable = "Year",
      controls.identifier = c(1:17)[-iter], #Choose as controls all other countries
      treatment.identifier = iter, 
      time.predictors.prior = c(1995:2012),
      time.optimize.ssr = c(1995:2012), 
      time.plot = c(1995:2017),
      unit.names.variable = 'Country'
    )
  
  # run synth
  synth.out <- synth(
    data.prep.obj = dataprep.out,
    method = "BFGS"
  )
  
  # store gaps
  store[,iter] <- dataprep.out$Y1plot - (dataprep.out$Y0plot %*% synth.out$solution.w)
}

# now do figure
data <- store
rownames(data) <- 1995:2017

#Perform SCM again for Ukraine to store the results
syn <- dataprep(
  foo = countries, 
  predictors = c('russia_trade_dependence', 'HDI', 'Polity', 'Inflation_prices', 'GFCF'), 
  special.predictors = list(
    list('GDP_2011', 2000, "mean"),
    list('GDP_2011', 2012, "mean")),
  dependent = "GDP_2011", 
  unit.variable = "Id",
  time.variable = "Year",
  controls.identifier = c(1:17),
  treatment.identifier = 18, 
  time.predictors.prior = c(1995:2012),
  time.optimize.ssr = c(1995:2012), 
  time.plot = c(1995:2017),
  unit.names.variable = 'Country')

synth.out <- synth(syn)

#Add Ukraine data to the results for other countries
data <- cbind(store, syn$Y1plot - (syn$Y0plot %*% synth.out$solution.w))
colnames(data)[18] <- "Ukraine"

#Set bounds in gaps data
gap.start     <- 1
gap.end       <- nrow(data)
years         <- 1995:2017
gap.end.pre  <- which(rownames(data)=="2012")

#MSPE Pre-Treatment
mse <- apply(data[ gap.start:gap.end.pre,]^2,2,mean)
ukraine.mse <- as.numeric(mse[18])

# Exclude states with 5 times higher MSPE than Ukraine to get cleaner results
data_trunc <- data[,mse<5*ukraine.mse]
Cex.set <- .75


#Plot placebo only for countries with MSPE <
plot(years,data_trunc[gap.start:gap.end,which(colnames(data_trunc)=="Ukraine")],
     xlab="Year",
     xlim=c(1995,2017),ylab="Gap in GDP per capita (2011 $ (PPP))",
     type="l",lwd=2,col="black",
     xaxs="i",yaxs="i",
     ylim = c(-2500, 2500))

# Add lines for control states
for (i in 1:ncol(data_trunc)) { lines(years,data_trunc[gap.start:gap.end,i],col="gray") }

## Add Ukraine line
lines(years,data_trunc[gap.start:gap.end,which(colnames(data_trunc)=="Ukraine")],lwd=2,col="black")

# Add grid
abline(v=2012,lty="dotted",lwd=2)
abline(h=0,lty="dashed",lwd=2)

#Ratio of MSPE before and after the treatment
MSP <- matrix(NA,length(1995:2017),18)
colnames(MSP) <- unique(countries$Country)

#  MSPE Plots
mse_pre <- apply(data[gap.start:gap.end.pre,]^2,2,mean)
mse_post <- apply(data[(gap.end.pre + 1):gap.end,]^2,2,mean)
ratio <- mse_post/mse_pre
ratio <- sort(ratio, decreasing = FALSE)

par(mai=c(1,2,1,1))
cols <- c("gray80", "gray50")[as.numeric(names(ratio)=="Ukraine")+1]  
barplot(ratio, horiz=TRUE,names.arg=names(ratio),las=1, col=cols)

me_pre <- apply(data[gap.start:gap.end.pre,],2,mean)
me_post <- apply(data[(gap.end.pre + 1):gap.end,],2,mean)
ratio <- me_post/me_pre
ratio <- sort(ratio, decreasing = FALSE)


MSPE.pre <- rep(NA, 18)
MSPE.post <- rep(NA, 18)

for (i in 1:18) {
  MSPE.pre[i] <- mean(data[1:18,i])
  MSPE.post[i] <- mean(data[19:23,i])
}

ratio <- MSPE.post/MSPE.pre
names(ratio)= unique(countries$Country)

MSPE <- matrix(c(MSPE.pre, MSPE.post), byrow = TRUE, nrow=2, ncol = 18)
colnames(MSPE) <- unique(countries$Country)
rownames(MSPE) <- c("pre", "post")
MSPE

mape = data.frame(t(MSPE))
names = substr(rownames(mape), 1, 3) 

ggplot(mape, aes(pre,post)) + 
  geom_point() + 
  xlab("Mean gap before treatment") +
  ylab("Mean gap after treatment") +
  scale_y_continuous(expand = c(0,0), limits = c(-2500, 2500)) +
  scale_x_continuous(expand = c(0,0), limits = c(-1000, 1000)) +
  geom_text(aes(label=names), nudge_x =50, nudge_y = 50, check_overlap = TRUE) +
  geom_rect(mapping=aes(xmin=-1000, xmax=127.4836, ymin=-2500, ymax=-1438.9023), 
            color="black", 
            fill = 'gray', 
            linetype = 'dashed')+
  theme_classic()


#Placebo plot with values adjusted to 2012 levels
data <- store
rownames(data) <- 1995:2017
data <- cbind(data, syn$Y1plot - (syn$Y0plot %*% synth.out$solution.w))
colnames(data)[18] <- "Ukraine"

gap2012 <- data[18,1:18]
after.treat <- data[18:23, 1:18]
after.treat2 <- sweep(after.treat, 2, gap2012)
rownames(after.treat2) <- 2012:2017

# Plot
years <- 2012:2017

plot(after.treat2[1:5,18], xaxt = "n",
     xlab="Year",ylab="Gap in per capita GDP (2011 international US $ (PPP))",
     type="l",lwd=2,col="black", ylim =c(-2000,2000))

axis(1, at=1:5, labels=c(2012, 2013, 2014, 2015, 2016, 2017))

# Add lines for control states
for (i in 1:17) {lines(after.treat2[,i],col="gray") }

# Add Ukraine Line
lines(after.treat2[,18],lwd=2,col="black")

#####################################################################
#####################################################################
########################   Leave One Out   ##########################
#####################################################################
#####################################################################

y <- c(1995:2017)

# No slovenia
syn <- dataprep(
  foo = countries, 
  predictors = c('russia_trade_dependence', 'HDI', 'Polity', 'Inflation_prices', 'GFCF'), 
  special.predictors = list(
    list('GDP_2011', 2000, "mean"),
    list('GDP_2011', 2012, "mean")),
  dependent = "GDP_2011", 
  unit.variable = "Id",
  time.variable = "Year",
  controls.identifier = c(1:17)[-14],
  treatment.identifier = 18, 
  time.predictors.prior = c(1995:2012),
  time.optimize.ssr = c(1995:2012), 
  time.plot = c(1995:2017),
  unit.names.variable = 'Country')

#Perform the optimization procedure
synth.out <- synth(syn)

synth.tables <- synth.tab(
  dataprep.res = syn,
  synth.res = synth.out)
print(synth.tables)

loo1 = syn$Y0plot %*% synth.out$solution.w

path.plot(dataprep.res = syn, synth.res = synth.out, Legend.position=c("topleft"), Ylab = 'per capita GDP, 2011 international $ (PPP)')
abline(v=2012)

countries$GDP_2011[countries$Country=="Ukraine"][19:23]- loo1[19:23]
mean(countries$GDP_2011[countries$Country=="Ukraine"][19:23]- loo1[19:23])

t.test(alpha1t, countries$GDP_2011[countries$Country=="Ukraine"][19:23]- loo1[19:23],alternative = "two.sided" )
wilcox.test(alpha1t, countries$GDP_2011[countries$Country=="Ukraine"][19:23]- loo1[19:23] ,alternative = "two.sided")

# No Bulgaria
syn1 <- dataprep(
  foo = countries, 
  predictors = c('russia_trade_dependence', 'HDI', 'Polity', 'Inflation_prices', 'GFCF'), 
  special.predictors = list(
    list('GDP_2011', 2000, "mean"),
    list('GDP_2011', 2012, "mean")),
  dependent = "GDP_2011", 
  unit.variable = "Id",
  time.variable = "Year",
  controls.identifier = c(1:17)[-4],
  treatment.identifier = 18, 
  time.predictors.prior = c(1995:2012),
  time.optimize.ssr = c(1995:2012), 
  time.plot = c(1995:2017),
  unit.names.variable = 'Country')

synth.out <- synth(syn1)

synth.tables <- synth.tab(
  dataprep.res = syn1,
  synth.res = synth.out)
print(synth.tables)

loo2 = syn1$Y0plot %*% synth.out$solution.w

path.plot(dataprep.res = syn1, synth.res = synth.out, Legend.position=c("topleft"), Ylab = 'per capita GDP, 2011 international $ (PPP)')
abline(v=2012)

countries$GDP_2011[countries$Country=="Ukraine"][19:23]- loo2[19:23]
mean(countries$GDP_2011[countries$Country=="Ukraine"][19:23]- loo2[19:23])

# An unpaired t-test is equivalent to a two-sample t-test
t.test(alpha1t, countries$GDP_2011[countries$Country=="Ukraine"][19:23]- loo2[19:23],alternative = "two.sided" )
wilcox.test(alpha1t, countries$GDP_2011[countries$Country=="Ukraine"][19:23]- loo2[19:23] ,alternative = "two.sided")

# No Armenia
syn1 <- dataprep(
  foo = countries, 
  predictors = c('russia_trade_dependence', 'HDI', 'Polity', 'Inflation_prices', 'GFCF'), 
  special.predictors = list(
    list('GDP_2011', 2000, "mean"),
    list('GDP_2011', 2012, "mean")),
  dependent = "GDP_2011", 
  unit.variable = "Id",
  time.variable = "Year",
  controls.identifier = c(1:17)[-1],
  treatment.identifier = 18, 
  time.predictors.prior = c(1995:2012),
  time.optimize.ssr = c(1995:2012), 
  time.plot = c(1995:2017),
  unit.names.variable = 'Country')

synth.out <- synth(syn1)


synth.tables <- synth.tab(
  dataprep.res = syn1,
  synth.res = synth.out)
print(synth.tables)

loo3 = syn1$Y0plot %*% synth.out$solution.w

path.plot(dataprep.res = syn1, synth.res = synth.out, Legend.position=c("topleft"), Ylab = 'per capita GDP, 2011 international $ (PPP)')
abline(v=2012)

countries$GDP_2011[countries$Country=="Ukraine"][19:23]- loo3[19:23]
mean(countries$GDP_2011[countries$Country=="Ukraine"][19:23]- loo3[19:23])

t.test(alpha1t, countries$GDP_2011[countries$Country=="Ukraine"][19:23]- loo3[19:23],alternative = "two.sided" )
wilcox.test(alpha1t, countries$GDP_2011[countries$Country=="Ukraine"][19:23]- loo3[19:23] ,alternative = "two.sided")

# No Moldova
syn1 <- dataprep(
  foo = countries, 
  predictors = c('russia_trade_dependence', 'HDI', 'Polity', 'Inflation_prices', 'GFCF'), 
  special.predictors = list(
    list('GDP_2011', 2000, "mean"),
    list('GDP_2011', 2012, "mean")),
  dependent = "GDP_2011", 
  unit.variable = "Id",
  time.variable = "Year",
  controls.identifier = c(1:17)[-17],
  treatment.identifier = 18, 
  time.predictors.prior = c(1995:2012),
  time.optimize.ssr = c(1995:2012), 
  time.plot = c(1995:2017),
  unit.names.variable = 'Country')

synth.out <- synth(syn1)

synth.tables <- synth.tab(
  dataprep.res = syn1,
  synth.res = synth.out)
print(synth.tables)

loo4 = syn1$Y0plot %*% synth.out$solution.w

path.plot(dataprep.res = syn1, synth.res = synth.out, Legend.position=c("topleft"), Ylab = 'per capita GDP, 2011 international $ (PPP)')
abline(v=2012)

mean(countries$GDP_2011[countries$Country=="Ukraine"][19:23]- loo4[19:23])

t.test(alpha1t, countries$GDP_2011[countries$Country=="Ukraine"][19:23]- loo4[19:23],alternative = "two.sided" )
wilcox.test(alpha1t, countries$GDP_2011[countries$Country=="Ukraine"][19:23]- loo4[19:23] ,alternative = "two.sided")

syn <- dataprep(
  foo = countries, 
  predictors = c('russia_trade_dependence', 'HDI', 'Polity', 'Inflation_prices', 'GFCF'), 
  special.predictors = list(
    list('GDP_2011', 2000, "mean"),
    list('GDP_2011', 2012, "mean")),
  dependent = "GDP_2011", 
  unit.variable = "Id",
  time.variable = "Year",
  controls.identifier = c(1:17),
  treatment.identifier = 18, 
  time.predictors.prior = c(1995:2012),
  time.optimize.ssr = c(1995:2012), 
  time.plot = c(1995:2017),
  unit.names.variable = 'Country')

#Perform the optimization procedure
synth.out <- synth(syn)

path.plot(dataprep.res = syn, synth.res = synth.out, Legend.position=c("topleft"), Ylab = 'per capita GDP, 2011 international $ (PPP)', Legend = c("Treated", "Synthetic", "Leave-one-out"))
abline(v=2012)
lines(c(1995:2017), loo1,col="gray") 
lines(c(1995:2017), loo2,col="gray") 
lines(c(1995:2017), loo3,col="gray") 
lines(c(1995:2017), loo4,col="gray") 

############################################################################################
############################################################################################
####################################GAS DISPUTES 2009#######################################
############################################################################################
############################################################################################

syn <- dataprep(
  foo = countries, 
  predictors = c('russia_trade_dependence', 'HDI', 'Polity', 'Inflation_prices', 'GFCF'), 
  special.predictors = list(
    list('GDP_2011', 2000, "mean"),
    list('GDP_2011', 2008, "mean")),
  dependent = "GDP_2011", 
  unit.variable = "Id",
  time.variable = "Year",
  controls.identifier = c(1:17),
  treatment.identifier = 18, 
  time.predictors.prior = c(1995:2008), #Redefined treatment period
  time.optimize.ssr = c(1995:2008), 
  time.plot = c(1995:2012), #Check the results before the actual treatment takes place
  unit.names.variable = 'Country')

synth.out <- synth(syn)

synth.tables <- synth.tab(
  dataprep.res = syn,
  synth.res = synth.out)
print(synth.tables)

path.plot(dataprep.res = syn, 
          synth.res = synth.out, 
          Legend.position=c("topleft"), 
          Ylab = "per capita GDP, 2011 international $ (PPP)")
abline(v=2008, lty = 3)

q <- syn$Y1plot - (syn$Y0plot %*% synth.out$solution.w)
synthetic.values <- syn$Y0plot %*% synth.out$solution.w

#Mean difference in years 2009-2012
mean.diff <- mean(q[15:18])

years <- c(1995:2017)
new.values <- synthetic.values[19:23] + mean.diff
new.val <- syn$Y1plot[1:18]
new.val <- c(new.val, new.values)

countries$GDP_2011[countries$Country == 'Ukraine']

#Placebo test for 2009 Gas Disputes
store <- matrix(NA,length(1995:2012),17)
colnames(store) <- unique(countries$Country)[-18]

# run placebo test
for(iter in 1:17){
  dataprep.out <-
    syn <- dataprep(
      foo = countries, 
      predictors = c('russia_trade_dependence', 'HDI', 'Polity', 'Inflation_prices', 'GFCF'), 
      special.predictors = list(
        list('GDP_2011', 2000, "mean"),
        list('GDP_2011', 2008, "mean")),
      dependent = "GDP_2011", 
      unit.variable = "Id",
      time.variable = "Year",
      controls.identifier = c(1:17)[-iter],
      treatment.identifier = iter, 
      time.predictors.prior = c(1995:2008),
      time.optimize.ssr = c(1995:2008), 
      time.plot = c(1995:2012),
      unit.names.variable = 'Country'
    )
  
  # run synth
  synth.out <- synth(
    data.prep.obj = dataprep.out,
    method = "BFGS"
  )
  
  # store gaps
  store[,iter] <- dataprep.out$Y1plot - (dataprep.out$Y0plot %*% synth.out$solution.w)
}

# now do figure
data <- store
rownames(data) <- 1995:2012

syn <- dataprep(
  foo = countries, 
  predictors = c('russia_trade_dependence', 'HDI', 'Polity', 'Inflation_prices', 'GFCF'), 
  special.predictors = list(
    list('GDP_2011', 2000, "mean"),
    list('GDP_2011', 2008, "mean")),
  dependent = "GDP_2011", 
  unit.variable = "Id",
  time.variable = "Year",
  controls.identifier = c(1:17),
  treatment.identifier = 18, 
  time.predictors.prior = c(1995:2008),
  time.optimize.ssr = c(1995:2008), 
  time.plot = c(1995:2012),
  unit.names.variable = 'Country')

synth.out <- synth(syn)

data <- cbind(data, syn$Y1plot - (syn$Y0plot %*% synth.out$solution.w))
colnames(data)[18] <- "Ukraine"

# Set bounds in gaps data
gap.start     <- 1
gap.end       <- nrow(data)
years         <- 1995:2012
gap.end.pre  <- which(rownames(data)=="2008")

#  MSPE Pre-Treatment
mse <- apply(data[ gap.start:gap.end.pre,]^2,2,mean)
ukraine.mse <- as.numeric(mse[18])
# Exclude states with 5 times higher MSPE than Ukraine
data <- data[,mse<5*ukraine.mse]
Cex.set <- .75

# Plot
plot(years,data[gap.start:gap.end,which(colnames(data)=="Ukraine")],
     xlab="year",
     xlim=c(1995,2012),ylab="Gap in GDP per capita (2011 international $, PPP)",
     type="l",lwd=2,col="black",
     xaxs="i",yaxs="i", ylim =c(-2000,2000))

# Add lines for control states
for (i in 1:18) { lines(years,data[gap.start:gap.end,i],col="gray") }

## Add Ukraine Line
lines(years,data[gap.start:gap.end,which(colnames(data)=="Ukraine")],lwd=2,col="black")

# Add grid
abline(v=2008,lty="dotted",lwd=2)
abline(h=0,lty="dashed",lwd=2)

############################################################################################
############################################################################################
####################################ORANGE REVOLUTION#######################################
############################################################################################
############################################################################################

syn <- dataprep(
  foo = countries, 
  predictors = c('russia_trade_dependence', 'HDI', 'Polity', 'Inflation_prices', 'GFCF'), 
  special.predictors = list(
    list('GDP_2011', 1995:2003, "mean")),
  dependent = "GDP_2011", 
  unit.variable = "Id",
  time.variable = "Year",
  controls.identifier = c(1:17),
  treatment.identifier = 18, 
  time.predictors.prior = c(1995:2003),
  time.optimize.ssr = c(1995:2003), 
  time.plot = c(1995:2012),
  unit.names.variable = 'Country')

synth.out <- synth(syn)

synth.tables <- synth.tab(
  dataprep.res = syn,
  synth.res = synth.out)
print(synth.tables)

path.plot(dataprep.res = syn, synth.res = synth.out, Legend.position=c("topleft"), Ylab = 'per capita GDP, 2011 $ PPP')
abline(v=2003)

gaps.plot(dataprep.res = syn, synth.res = synth.out, Ylab = 'Prediction errors')
abline(v=2003)

store <- matrix(NA,length(1995:2012),17)
colnames(store) <- unique(countries$Country)[-18]

# run placebo test
for(iter in 1:17)
{
  dataprep.out <-
    syn <- dataprep(
      foo = countries, 
      predictors = c('russia_trade_dependence', 'HDI', 'Polity', 'Inflation_prices', 'GFCF'), 
      special.predictors = list(
        list('GDP_2011', 1995:2003, "mean")),
      dependent = "GDP_2011", 
      unit.variable = "Id",
      time.variable = "Year",
      controls.identifier = c(1:17)[-iter],
      treatment.identifier = iter, 
      time.predictors.prior = c(1995:2003),
      time.optimize.ssr = c(1995:2003), 
      time.plot = c(1995:2012),
      unit.names.variable = 'Country'
    )
  
  # run synth
  synth.out <- synth(
    data.prep.obj = dataprep.out,
    method = "BFGS"
  )
  
  # store gaps
  store[,iter] <- dataprep.out$Y1plot - (dataprep.out$Y0plot %*% synth.out$solution.w)
}

# now do figure
data <- store
rownames(data) <- 1995:2012

syn <- dataprep(
  foo = countries, 
  predictors = c('russia_trade_dependence', 'HDI', 'Polity', 'Inflation_prices', 'GFCF'), 
  special.predictors = list(
    list('GDP_2011', 1995:2003, "mean")),
  dependent = "GDP_2011", 
  unit.variable = "Id",
  time.variable = "Year",
  controls.identifier = c(1:17),
  treatment.identifier = 18, 
  time.predictors.prior = c(1995:2003),
  time.optimize.ssr = c(1995:2003), 
  time.plot = c(1995:2012),
  unit.names.variable = 'Country')

synth.out <- synth(syn)

data <- cbind(data, syn$Y1plot - (syn$Y0plot %*% synth.out$solution.w))
colnames(data)[18] <- "Ukraine"

# Set bounds in gaps data
gap.start     <- 1
gap.end       <- nrow(data)
years         <- 1995:2012
gap.end.pre  <- which(rownames(data)=="2003")

#  MSPE Pre-Treatment
mse <- apply(data[ gap.start:gap.end.pre,]^2,2,mean)
ukraine.mse <- as.numeric(mse[18])
# Exclude states with 5 times higher MSPE than Ukraine
data <- data[,mse<5*ukraine.mse]
Cex.set <- .75

# Plot
plot(years,data[gap.start:gap.end,which(colnames(data)=="Ukraine")],
     xlab="year",
     xlim=c(1995,2012),ylab="Gap in per capita GDP (2011 international $, PPP)",
     type="l",lwd=2,col="black",
     xaxs="i",yaxs="i", ylim =c(-3000,3000))

# Add lines for control states
for (i in 1:18) { lines(years,data[gap.start:gap.end,i],col="gray") }

## Add Ukraine Line
lines(years,data[gap.start:gap.end,which(colnames(data)=="Ukraine")],lwd=2,col="black")

# Add grid
abline(v=2003,lty="dotted",lwd=2)
abline(h=0,lty="dashed",lwd=2)









#####################################################################
#####################################################################
######################                     ##########################
###################### Regional Analysis   ##########################
######################                     ##########################
#####################################################################
#####################################################################

regions <- read.csv2("Bluszcz_Valente_repdata_regions.csv")
regions$Name <- as.character(regions$Name)
regions$invest_relative = regions$InvestUAH/regions$GDP*100
regions$Export_relative = regions$Export_UAH/regions$GDP*100

#####################################################################
#####################      SCM for Donbass   ########################
#####################################################################

#SC model for Donetsk
syn <- dataprep(
  foo = regions, 
  predictors = c("Export_relative", "invest_relative", "Unemployment"), 
  special.predictors = list(
    list('gdppc', 2004:2012, "mean")),
  dependent = "gdppc", 
  unit.variable = "Id",
  time.variable = "Year",
  controls.identifier = c(1:22),
  treatment.identifier = 24, 
  time.predictors.prior = c(2004:2012),
  time.optimize.ssr = c(2004:2012), 
  time.plot = c(2004:2016),
  unit.names.variable = 'Name')

synth.out <- synth(syn)

synth.tables <- synth.tab(
  dataprep.res = syn,
  synth.res = synth.out)
print(synth.tables)

syn$Y0plot %*% synth.out$solution.w
syn$Y1plot - (syn$Y0plot %*% synth.out$solution.w)

contr = (syn$Y0plot %*% synth.out$solution.w)[10:13]
cost = (syn$Y1plot - (syn$Y0plot %*% synth.out$solution.w))[10:13]
perc = cost/contr
mean(cost)
mean(perc)

#Plot the trajectory between treatment unit and the synthetic unit
path.plot(dataprep.res = syn, synth.res = synth.out, Legend.position=c("topleft"), Ylab = "Per capita GRP (2011 international $, PPP)")
abline(v=2012)

#Plot the gap between treated and synthetic units
gaps.plot(dataprep.res = syn, synth.res = synth.out, Ylab = "Gaps in Donetsk's GRP")
abline(v=2012)

#####################################################################
#####################      SCM for Luhansk   ########################
#####################################################################

syn <- dataprep(
  foo = regions, 
  predictors = c("Export_relative", "invest_relative", "Unemployment"), 
  special.predictors = list(
    list('gdppc', 2004:2012, "mean")),
  dependent = "gdppc", 
  unit.variable = "Id",
  time.variable = "Year",
  controls.identifier = c(1:22),
  treatment.identifier = 25, 
  time.predictors.prior = c(2004:2012),
  time.optimize.ssr = c(2004:2012), 
  time.plot = c(2004:2016),
  unit.names.variable = 'Name')

synth.out <- synth(syn)

synth.tables <- synth.tab(
  dataprep.res = syn,
  synth.res = synth.out)
print(synth.tables)

syn$Y0plot %*% synth.out$solution.w
syn$Y1plot - (syn$Y0plot %*% synth.out$solution.w)

luhansk_cost = (syn$Y1plot - (syn$Y0plot %*% synth.out$solution.w))[10:13]
luhansk_contr = (syn$Y0plot %*% synth.out$solution.w)[10:13]
perc_error = luhansk_cost/luhansk_contr
perc_error
mean(luhansk_cost) 
mean(perc_error)

path.plot(dataprep.res = syn, synth.res = synth.out, Legend.position=c("topleft"), Ylab = "Per capita GRP (2011 international $, (PPP))")
abline(v=2012)

#Plot the gap between treated and synthetic units
gaps.plot(dataprep.res = syn, synth.res = synth.out)
abline(v=2012)

#####################################################################
#####################      Placebo tests     ########################
#####################################################################

#Placebo tests
store <- matrix(NA,length(2004:2016),22)
colnames(store) <- unique(regions$Name)[c(-23, -24, -25)]

# run placebo test
for(iter in 1:22)
{
  dataprep.out <-
    syn <- dataprep(
      foo = regions, 
      predictors = c("Export_relative", "invest_relative", "Unemployment"), 
      special.predictors = list(
        list('gdppc', 2004:2012, "mean")),
      dependent = "gdppc", 
      unit.variable = "Id",
      time.variable = "Year",
      controls.identifier = c(1:22)[-iter],
      treatment.identifier = iter, 
      time.predictors.prior = c(2004:2012),
      time.optimize.ssr = c(2004:2012), 
      time.plot = c(2004:2016),
      unit.names.variable = 'Name'
    )
  
  # run synth
  synth.out <- synth(
    data.prep.obj = dataprep.out,
    method = "BFGS"
  )
  
  # store gaps
  store[,iter] <- dataprep.out$Y1plot - (dataprep.out$Y0plot %*% synth.out$solution.w)
}

#Plot the results
data <- store
rownames(data) <- 2004:2016

syn <- dataprep(
  foo = regions, 
  predictors = c("Export_relative", "invest_relative", "Unemployment"), 
  special.predictors = list(
    list('gdppc', 2004:2012, "mean")),
  dependent = "gdppc", 
  unit.variable = "Id",
  time.variable = "Year",
  controls.identifier = c(1:22),
  treatment.identifier = 24, 
  time.predictors.prior = c(2004:2012),
  time.optimize.ssr = c(2004:2012), 
  time.plot = c(2004:2016),
  unit.names.variable = 'Name')

synth.out <- synth(syn)

syn2 <- dataprep(
  foo = regions, 
  predictors = c("Export_relative", "invest_relative", "Unemployment"), 
  special.predictors = list(
    list('gdppc', 2004:2012, "mean")),
  dependent = "gdppc", 
  unit.variable = "Id",
  time.variable = "Year",
  controls.identifier = c(1:22),
  treatment.identifier = 25, 
  time.predictors.prior = c(2004:2012),
  time.optimize.ssr = c(2004:2012), 
  time.plot = c(2004:2016),
  unit.names.variable = 'Name')

synth.out2 <- synth(syn2)

data <- cbind(data, syn$Y1plot - (syn$Y0plot %*% synth.out$solution.w))
colnames(data)[23] <- "Donetsk"
data <- cbind(data, syn2$Y1plot - (syn2$Y0plot %*% synth.out2$solution.w))
colnames(data)[24] <- "Luhansk"

# Set bounds in gaps data
gap.start     <- 1
gap.end       <- nrow(data)
years         <- 2004:2016
gap.end.pre  <- which(rownames(data)=="2012")

# Plot
plot(years,data[gap.start:gap.end,which(colnames(data)=="Donetsk")],
     xlab="year",
     xlim=c(2004,2016),ylab="Gap in GDP per capita (2011 $ PPP)",
     type="l",lwd=2,col="black",lty = 2, 
     xaxs="i",yaxs="i", ylim =c(-7000,7000))

# Add lines for control regions
for (i in 1:22) { lines(years,data[gap.start:gap.end,i],col="gray") }

## Add Donetsk Line
lines(years,data[gap.start:gap.end,which(colnames(data)=="Donetsk")],lwd=2,col="black", lty = 2)
lines(years,data[gap.start:gap.end,which(colnames(data)=="Luhansk")],lwd=2,col="black", lty = 1)
legend(2004, 7000, legend=c("Luhansk", "Donetsk"),
       col=c("black", "black"), lty=1:2, lwd = 2)
# Add grid
abline(v=2012,lty="dotted",lwd=1)
abline(h=0,lty="dashed",lwd=1)

#  MSPE Pre-Treatment
mse_pre <- apply(data[gap.start:gap.end.pre,]^2,2,mean)
mse_post <- apply(data[(gap.end.pre + 1):gap.end,]^2,2,mean)
ratio <- mse_post/mse_pre
ratio <- sort(ratio, decreasing = FALSE)

par(mai=c(1,2,1,1))  
cols <- c("gray80","gray80","gray80","gray80","gray80","gray80","gray80","gray80","gray80","gray80","gray80","gray80","gray80","gray80","gray80","gray80","gray80","gray80","gray80","gray80","gray80","gray50", "gray80", "gray50")  
barplot(ratio, main="Ratio of MSE", horiz=TRUE,names.arg=names(ratio),las=1, col = cols)

MSPE.pre <- rep(NA, 24)
MSPE.post <- rep(NA, 24)

for (i in 1:24) {
  MSPE.pre[i] <- mean(data[1:9,i], na.rm = TRUE)
  MSPE.post[i] <- mean(data[10:12,i])
}

MSPE <- matrix(c(MSPE.pre, MSPE.post), byrow = TRUE, nrow=2, ncol = 24)
colnames(MSPE) <- unique(regions$Name)[-22]
rownames(MSPE) <- c("pre", "post")
MSPE

mape = data.frame(t(MSPE))
names = substr(rownames(mape), 1, 3) 

ggplot(mape, aes(pre,post)) + 
  geom_point() + 
  scale_y_continuous(expand = c(0,0), limits = c(-5000, 2500)) +
  scale_x_continuous(expand = c(0,0), limits = c(-1000, 1000)) +
  xlab("Mean gap before treatment") +
  ylab("Mean gap after treatment") +
  geom_text(aes(label=names), nudge_x =80, nudge_y = 100, check_overlap = TRUE) +
  geom_rect(mapping=aes(xmin=-1000, xmax=243.6454, ymin=-5000, ymax=-3797.7963), 
            color="black", 
            fill = 'gray', 
            linetype = 'dashed')+
  geom_rect(mapping=aes(xmin=-1000, xmax=-0.1035682, ymin=-5000, ymax=-3047.7948658), 
            color="black", 
            fill = 'gray', 
            linetype = 'dashed')+
  theme_classic()

#####################################################################
#####################################################################
####################        Spillovers       ########################
#####################################################################
#####################################################################


#####################################################################
###############   country-level spillovers ##########################
#####################################################################

# Build data with outcomes only and control units on columns
colnames(countries)
attach(countries)
dat <- data.frame(Year, Country, GDP_2011)
datwide <- dcast(dat, Year ~ Country, value.var="GDP_2011")

rownames(datwide) <- datwide$Year
datwide2<- data.frame(Ukraine=datwide[, 19], datwide[,-19])
datwide2 <- datwide2[,-2]

# Ukraine borders with six countries, excl. Russia: Poland, Slovakia, Hungary, Romania, Moldova, and Belarus

#Build interference matrix
#indicators of all possibly affected states
#UKR keeps the value 1
ind2 = rep(0,18)
neighb <- colnames(datwide2)  %in% c("Poland", "Slovakia", "Hungary","Romania", "Moldova","Belarus", "Ukraine")
dim(datwide2)
ind2[neighb] <- 1
length(ind2)

n2<-length(colnames(datwide2))
# All 18 possible states
A2 = diag(n2)
dim(A2)
#Interact the two
A2 = A2[,which(!!ind2)]
dim(A2)


# Pull apart pre-treatment and post-treatment
t2 <- 18  # n. pretreatm periods
s2 <- 5 # n. posttreatm periods (2013-2017)
Y0m = as.matrix(datwide2[1:t2,])
Y1m = as.matrix(datwide2[1:s2 + t2,])

class(Y1m) # matrix
#---------------------------------------------
#              Run Models
#---------------------------------------------
sum(neighb)
spill = lapply(1:s2,
               function(i) sp_andrews(Y0m,Y1m[i,],A2,loo=F,C=diag(nrow(A2))[,1]))

# FOR EACH POSTTREATMENT PERIOD (1-5), obtain pvalue of joint spillovers on untreated
# joint spillovers only in 2014-17

# Find spillover-adjusted causal effects only for the spillovered years
spillsign <- which(sapply(spill,
                          function(x) x$pval)<0.05)

# Indicator for running leave-one-out, Normal inference
loo = F
normal = F

# ONLY FOR
all_post_periods = lapply(c(1:s2)[spillsign],
                          function(i) sp_andrews_te(Y0m,Y1m[i,],A2,
                                                    loo,normal))
all_post_periods
# For all but the first posttreatment year, test rejects there is no spillover effects in those years
# H0: No spillovers accepted (NOT rejected) in all posttreatment period but 2017
length(all_post_periods)


# Spillover adjusted gaps posttreatment for 2017
# pvalues reveals whether the spillover-adjusted TE are stat sign or not
tau_t  = sapply(all_post_periods,
                function(x) x$Estimates[1])
pval_t = sapply(all_post_periods,
                function(x) x$pval)
ci_t   = sapply(all_post_periods,
                function(x) x$CI)

#####################################################################
###############   region-level spillovers  ##########################
#####################################################################

attach(regions)
dat <- data.frame(Year, Name, gdppc)
datwide <- dcast(dat, Year ~ Name, value.var="gdppc")

######### Donetsk ##################
datwide2<- data.frame(Donetsk=datwide[, 6], datwide[,-c(6,14)])
datwide2 <- datwide2[,-2]

# Build interference matrix
#indicators of all possibly affected states
# treated keeps the value 1
ind2 = rep(0,24)
neighb <- colnames(datwide2)  %in% c("Donetsk", "Zaporizhzhya", "Dnipropetrovsk","Kharkiv")
dim(datwide2)
ind2[neighb] <- 1
length(ind2)

n2<-length(colnames(datwide2))
# All 24 possible reg
A2 = diag(n2)
dim(A2)
#Interact the two
A2 = A2[,which(!!ind2)]
dim(A2)

nrow(datwide)
datwide$Year

# Pull apart pre-treatment and post-treatment
t2 <-11  # n. pretreatm periods
s2 <- 4 # n. posttreatm periods (2013-2016)
Y0m = as.matrix(datwide2[3:t2,])
Y1m = as.matrix(datwide2[1:s2 + t2,])

class(Y1m) # matrix
#---------------------------------------------
#              Run Models
#---------------------------------------------
spill = lapply(1:s2,
               function(i) sp_andrews(Y0m,Y1m[i,],A2,loo=F,C=diag(nrow(A2))[,1]))


# Find spillover-adjusted causal effects only for the spillovered years
spillsign <- which(sapply(spill,
                          function(x) x$pval)<0.05)
spillsign
#Indicator for running leave-one-out, Normal inference
loo = F
normal = F

all_post_periods = lapply(1:s2,
                          function(i) sp_andrews_te(Y0m,Y1m[i,],A2,
                                                    loo,normal))
unlist(all_post_periods)
# For all but the first posttreatment year, test rejects there is no spillover effects in those years
# H0: No spillovers accepted (NOT rejected) in all posttreatment period but 2017
length(all_post_periods)



# Spillover adjusted gaps posttreatment for 2017
# pvalues reveals whether the spillover-adjusted TE are stat sign or not
tau_t  = sapply(all_post_periods,
                function(x) x$Estimates[1])
pval_t = sapply(all_post_periods,
                function(x) x$pval)
ci_t   = sapply(all_post_periods,
                function(x) x$CI)

############ Luhansk ###############################

datwide <- dcast(dat, Year ~ Name, value.var="gdppc")
dim(datwide)

unique(regions$Name) 

rownames(datwide) <- datwide$Year
colnames(datwide)


datwide2<- data.frame(Luhansk=datwide[, 14], datwide[,-c(6,14)])
datwide2 <- datwide2[,-2]
dim(datwide2)
# Ukraine borders with six countries, excl. Russia: Poland, Slovakia, Hungary, Romania, Moldova, and Belarus

# Build interference matrix
#indicators of all possibly affected states
# treated keeps the value 1
ind2 = rep(0,24)
neighb <- colnames(datwide2) %in% c("Luhansk","Kharkiv")
dim(datwide2)
ind2[neighb] <- 1
length(ind2)

n2<-length(colnames(datwide2))
# All 24 possible reg
A2 = diag(n2)
dim(A2)
#Interact the two
A2 = A2[,which(!!ind2)]
dim(A2)

nrow(datwide)
datwide$Year

# Pull apart pre-treatment and post-treatment
t2 <-11  # n. pretreatm periods
s2 <- 4 # n. posttreatm periods (2013-2016)
Y0m = as.matrix(datwide2[3:t2,])
Y1m = as.matrix(datwide2[1:s2 + t2,])

class(Y1m) # matrix
#---------------------------------------------
#              Run Models
#---------------------------------------------
spill = lapply(1:s2,
               function(i) sp_andrews(Y0m,Y1m[i,],A2,loo=F,C=diag(nrow(A2))[,1]))

# Find spillover-adjusted causal effects only for the spillovered years
spillsign <- which(sapply(spill,
                          function(x) x$pval)<0.05)

spillsign
#Indicator for running leave-one-out, Normal inference
loo = F
normal = F

all_post_periods = lapply(1:s2,
                          function(i) sp_andrews_te(Y0m,Y1m[i,],A2,
                                                    loo,normal))
unlist(all_post_periods)
# For all but the first posttreatment year, test rejects there is no spillover effects in those years
# H0: No spillovers accepted (NOT rejected) in all posttreatment period but 2017
length(all_post_periods)

# Spillover adjusted gaps posttreatment for 2017
# pvalues reveals whether the spillover-adjusted TE are stat sign or not
tau_t  = sapply(all_post_periods,
                function(x) x$Estimates[1])
pval_t = sapply(all_post_periods,
                function(x) x$pval)
ci_t   = sapply(all_post_periods,
                function(x) x$CI)
