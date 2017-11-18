#' The \code{exprso} Package
#'
#' @description
#' Welcome to the \code{exprso} package!
#'
#' The \code{exprso} function imports data into the learning environment.
#'
#' See \code{\link{mod}} to process the data.
#'
#' See \code{\link{split}} to split off a test set.
#'
#' See \code{\link{fs}} to select features.
#'
#' See \code{\link{build}} to build models.
#'
#' See \code{\link{pl}} to build models high-throughput.
#'
#' See \code{\link{pipe}} to process pipelines.
#'
#' See \code{\link{buildEnsemble}} to build ensembles.
#'
#' See \code{\link{exprso-predict}} to deploy models.
#'
#' See \code{\link{conjoin}} to merge objects.
#'
#' @param x A matrix of feature data for all samples. Rows should
#'  contain samples and columns should contain features.
#' @param y A vector of outcomes for all samples. If
#'  \code{class(y) == "character"} or \code{class(y) == "factor"},
#'  \code{exprso} prepares data for binary or multi-class classification.
#'  Else, \code{exprso} prepares data for regression. If \code{y} is a
#'  matrix, the program assumes the first column is the outcome.
#' @return An \code{ExprsArray} object.
#'
#' @examples
#' \dontrun{
#' library(exprso)
#' library(golubEsets)
#' data(Golub_Merge)
#' array <- arrayEset(Golub_Merge, colBy = "ALL.AML", include = list("ALL", "AML"))
#' array <- modFilter(array, 20, 16000, 500, 5) # pre-filter Golub ala Deb 2003
#' array <- modTransform(array) # lg transform
#' array <- modNormalize(array, c(1, 2)) # normalize gene and subject vectors
#' arrays <- splitSample(array, percent.include = 67)
#' array.train <- fsStats(arrays[[1]], top = 0, how = "t.test")
#' array.train <- fsPrcomp(array.train, top = 50)
#' mach <- buildSVM(array.train, top = 5, kernel = "linear", cost = 1)
#' }
#' @export
exprso <- function(x, y){

  if(length(y) != nrow(x)) stop("Incorrect number of outcomes.")
  array <-
    new("ExprsArray",
        exprs = t(as.data.frame(x)), annot = as.data.frame(y),
        preFilter = NULL, reductionModel = NULL
    )

  # Prepare ExprsArray object using x and y input
  colnames(array@exprs) <- paste0("x", 1:ncol(array@exprs))
  colnames(array@exprs) <- make.names(colnames(array@exprs), unique = TRUE)
  rownames(array@annot) <- colnames(array@exprs)
  labels <- array@annot[,1]

  # Set sub-class to guide fs and build modules
  if(class(labels) == "character" | class(labels) == "factor"){
    if(length(unique(y)) == 2){
      print("Preparing data for binary classification.")
      class(array) <- "ExprsBinary"
      array@annot$defineCase <- ifelse(labels == unique(labels)[1], "Control", "Case")
    }else{
      print("Preparing data for multi-class classification.")
      class(array) <- "ExprsMulti"
      array@annot$defineCase <- factor(labels)
    }
  }else{
    print("Preparing data for regression.")
    class(array) <- "ExprsCont"
    array@annot$defineCase <- labels
  }

  # Remove features with any NA values
  if(any(is.na(array@exprs))){
    print("Removing features with NA values.")
    noNAs <- apply(array@exprs, 1, function(x) !any(is.na(x)))
    array@exprs <- array@exprs[noNAs, ]
  }

  return(array)
}

#' @name mod
#' @rdname mod
#'
#' @title Process Data
#'
#' @description
#' The \code{exprso} package includes these data process modules:
#'
#' - \code{\link{modSubset}}
#'
#' - \code{\link{modFilter}}
#'
#' - \code{\link{modTransform}}
#'
#' - \code{\link{modNormalize}}
#'
#' - \code{\link{modTMM}}
NULL

#' @name split
#' @rdname split
#'
#' @title Split Data
#'
#' @description
#' The \code{exprso} package includes these split modules:
#'
#' - \code{\link{splitSample}}
#'
#' - \code{\link{splitStratify}}
NULL

#' @name fs
#' @rdname fs
#'
#' @title Select Features
#'
#' @description
#' The \code{exprso} package includes these feature selection modules:
#'
#' - \code{\link{fsSample}}
#'
#' - \code{\link{fsNULL}}
#'
#' - \code{\link{fsANOVA}}
#'
#' - \code{\link{fsInclude}}
#'
#' - \code{\link{fsStats}}
#'
#' - \code{\link{fsPrcomp}}
#'
#' - \code{\link{fsEbayes}}
#'
#' - \code{\link{fsEdger}}
#'
#' - \code{\link{fsMrmre}}
#'
#' - \code{\link{fsPropd}}
#'
#' @details
#' Considering the high-dimensionality of most genomic datasets, it is prudent and often necessary
#'  to prioritize which features to include during classifier construction. Although there exists
#'  many feature selection methods, this package provides wrappers for some of the most popular ones.
#'  Each wrapper (1) pre-processes the \code{ExprsArray} input, (2) performs the feature selection,
#'  and (3) returns an \code{ExprsArray} output with an updated feature selection history.
#'  You can use, in tandem, any number of feature selection methods, and in any order.
#'
#' For all feature selection methods, \code{@@preFilter} and \code{@@reductionModel} stores the
#'  feature selection and dimension reduction history, respectively. This history gets passed
#'  along to prepare the test or validation set during model deployment, ensuring that these
#'  sets undergo the same feature selection and dimension reduction as the training set.
#'
#' Under the scenarios where users plan to apply multiple feature selection or dimension
#'  reduction steps, the \code{top} argument manages which features (e.g., gene expression values)
#'  to send through each feature selection or dimension reduction procedure. For \code{top},
#'  a numeric scalar indicates the number of top features to use, while a character vector
#'  indicates specifically which features to use. In this way, the user sets which features
#'  to feed INTO the \code{fs} method (NOT which features the user expects OUT). The example
#'  below shows how to apply dimension reduction to the top 50 features as selected by the
#'  Student's t-test. Set \code{top = 0} to pass all features through an \code{fs} method.
#'
#' Note that not all feature selection methods will generalize to multi-class data.
#'  A feature selection method will fail when applied to an \code{ExprsMulti} object
#'  unless that feature selection method has an \code{ExprsMulti} method.
NULL

#' @name build
#' @rdname build
#'
#' @title Build Models
#'
#' @description
#' The \code{exprso} package includes these build modules:
#'
#' - \code{\link{buildNB}}
#'
#' - \code{\link{buildLDA}}
#'
#' - \code{\link{buildSVM}}
#'
#' - \code{\link{buildANN}}
#'
#' - \code{\link{buildRF}}
#'
#' - \code{\link{buildDNN}}
#'
#' @details
#' These \code{build} methods construct a single classifier given an \code{ExprsArray}
#'  object and a set of parameters. This function returns an \code{ExprsModel} object.
#'  In the case of binary classification, these methods use an \code{ExprsBinary}
#'  object and return an \code{ExprsMachine} object. In the case of multi-class
#'  classification, these methods use an \code{ExprsMulti} object and return an
#'  \code{ExprsModule} object. In the case of multi-class classification, these methods
#'  harness the \code{\link{doMulti}} function to perform "1 vs. all" classifier
#'  construction. In the setting of four class labels, a single \code{build} call
#'  will return four classifiers that work in concert to make a single prediction
#'  of an unlabelled subject. For building multiple classifiers across a vast
#'  parameter space in a high-throughput manner, see \code{pl} methods.
#'
#' Like \code{\link{fs}} methods, \code{build} methods have a \code{top} argument
#'  which allows the user to specify which features to feed INTO the classifier
#'  build. This effectively provides the user with one last opportunity to subset
#'  the feature space based on prior feature selection or dimension reduction.
#'  For all build methods, \code{@@preFilter} and \code{@@reductionModel} will
#'  get passed along to the resultant \code{ExprsModel} object, again ensuring
#'  that any test or validation sets will undergo the same feature selection and
#'  dimension reduction in the appropriate steps when deploying the classifier.
#'  Set \code{top = 0} to pass all features through a \code{build} method.
NULL

#' @name pl
#' @rdname pl
#'
#' @title Deploy Pipeline
#'
#' @description
#' The \code{exprso} package includes these automated pipeline modules:
#'
#' - \code{\link{plCV}}
#'
#' - \code{\link{plGrid}}
#'
#' - \code{\link{plGridMulti}}
#'
#' - \code{\link{plMonteCarlo}}
#'
#' - \code{\link{plNested}}
NULL

#' @name pipe
#' @rdname pipe
#'
#' @title Process Pipelines
#'
#' @description
#' The \code{exprso} package includes these pipeline process modules:
#'
#' - \code{\link{pipeSubset}}
#'
#' - \code{\link{pipeFilter}}
#'
#' - \code{\link{pipeUnboot}}
NULL