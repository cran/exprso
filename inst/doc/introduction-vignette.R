## ---- echo = FALSE, out.width = '675pt', fig.retina = NULL---------------
knitr::include_graphics("exprso-diagram.jpg")

## ---- eval = FALSE-------------------------------------------------------
#  install.packages("exprso")
#  library(exprso)

## ---- echo = FALSE, message = FALSE--------------------------------------
library(exprso)
set.seed(1)

## ---- eval = FALSE-------------------------------------------------------
#  array <-
#    arrayExprs("some_example_data_file.txt", # tab-delimited file
#               colBy = "DX", # column name with class labels
#               include = list(c("Control"), c("ASD", "PDDNOS")),
#               begin = 11, # the i-th column where features begin
#               colID = "Subject.ID") # column name with subject ID)

## ---- message = FALSE----------------------------------------------------
library(golubEsets)
data(Golub_Merge)
array <-
  arrayExprs(Golub_Merge, # an ExpressionSet (abrv. eSet) object
             colBy = "ALL.AML", # column name with class labels
             include = list("AML", "ALL"))

## ---- eval = FALSE-------------------------------------------------------
#  array <-
#    new("ExprsArray",
#        exprs = some.expression.matrix,
#        annot = some.annotation.data.frame,
#        preFilter = NULL,
#        reductionModel = NULL)

## ------------------------------------------------------------------------
array[array$defineCase == "Case", "ALL.AML"]

## ------------------------------------------------------------------------
modSubset(array, colBy = "defineCase", include = "Case")
subset(array, subset = array$defineCase == "Case")

## ------------------------------------------------------------------------
arrays <-
  splitStratify(array,
                percent.include = 67,
                colBy = NULL)

array.train <- arrays[[1]]

## ------------------------------------------------------------------------
balance <-
  splitStratify(arrays[[2]],
                percent.include = 100,
                colBy = NULL)

array.test <- balance[[1]]

## ------------------------------------------------------------------------
array.train <-
  fsStats(array.train, top = 0, how = "t.test")

## ------------------------------------------------------------------------
array.train <-
  fsPrcomp(array.train, top = 50)

## ------------------------------------------------------------------------
plot(array.train)

## ------------------------------------------------------------------------
mach <-
  buildANN(array.train, top = 10, size = 5)

## ------------------------------------------------------------------------
pred <-
  predict(mach, array.test)

## ------------------------------------------------------------------------
calcStats(pred)

## ---- results = "hide", warning = FALSE----------------------------------
gs <-
  plGrid(array.train = array.train,
         array.valid = array.test,
         top = c(5, 10),
         how = "buildSVM",
         fold = 0,
         kernel = "linear",
         cost = 10^(-3:3)
)

## ------------------------------------------------------------------------
gs[, "train.plCV"]
gs$train.plCV

## ------------------------------------------------------------------------
pipeSubset(gs, colBy = "cost", include = 1)
subset(gs, subset = gs$cost == 1)

## ------------------------------------------------------------------------
ss <-
  ctrlSplitSet(func = "splitSample", percent.include = 67, replace = TRUE)
fs <-
  ctrlFeatureSelect(func = "fsStats", top = 0, how = "t.test")
gs <-
  ctrlGridSearch(func = "plGrid",
                 how = "buildSVM",
                 top = c(10, 25),
                 kernel = "linear",
                 cost = 10^(-3:3),
                 fold = 10)

## ---- results = "hide", warning = FALSE----------------------------------
boot <-
  plMonteCarlo(arrays[[1]],
               B = 5,
               ctrlSS = ss,
               ctrlFS = fs,
               ctrlGS = gs)

## ------------------------------------------------------------------------
calcMonteCarlo(boot, colBy = "valid.auc")

## ---- results = "hide"---------------------------------------------------
ens <- buildEnsemble(boot, top = 1, colBy = "valid.auc")
pred <- predict(ens, array.test, how = "majority")

## ---- echo = FALSE-------------------------------------------------------
calcStats(pred)

