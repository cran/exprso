% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/5.1-fs.R
\name{fsEdger}
\alias{fsEdger}
\title{Selects Features by Exact Test}
\usage{
fsEdger(object, top = 0, keep = 0, ...)
}
\arguments{
\item{object}{An \code{ExprsArray} object to undergo feature selection.}

\item{top}{A numeric scalar or character vector. A numeric scalar indicates
the number of top features that should undergo feature selection. A character vector
indicates specifically which features by name should undergo feature selection.
Set \code{top = 0} to include all features. A numeric vector can also be used
to indicate specific features by location, similar to a character vector.}

\item{keep}{A numeric scalar. Specifies the number of top features that should get
returned by the feature selection method. Use of \code{keep} is generally not
recommended, but can speed up analyses of large data.}

\item{...}{Arguments passed to the detailed function.}
}
\value{
Returns an \code{ExprsArray} object.
}
\description{
\code{fsEdger} selects features using the \code{exactTest} function
 from the \code{edgeR} package. This function does not normalize the data,
 but does estimate dispersion using the \code{estimateCommonDisp}
 and \code{estimateTagwiseDisp} functions.
}
\details{
The user can normalize the data before feature selection using the
 \code{modTMM} function. Note that applying \code{edgeR} to already normalized
 counts differs slightly from applying \code{edgeR} with normalization.
}
