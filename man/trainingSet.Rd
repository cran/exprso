% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/1.2-methods.R
\name{trainingSet}
\alias{trainingSet}
\title{Extract Training Set}
\usage{
trainingSet(splitSets)
}
\arguments{
\item{splitSets}{A two-item list. The result of a \code{split} method call.}
}
\value{
An \code{ExprsArray} object.
}
\description{
This function extracts the training set from the result of a
 \code{split} method call such as \code{splitSample} or \code{splitStratify}.
}
