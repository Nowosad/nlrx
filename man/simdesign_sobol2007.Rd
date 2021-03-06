% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/simdesign_helper.R
\name{simdesign_sobol2007}
\alias{simdesign_sobol2007}
\title{Add a sobol2007 simdesign to a nl object}
\usage{
simdesign_sobol2007(nl, samples, sobolnboot, sobolconf, nseeds, precision)
}
\arguments{
\item{nl}{nl object with a defined experiment}

\item{samples}{number of samples for the sobol sensitivity analysis}

\item{sobolnboot}{number of bootstrap replicates of the sobol sensitivity analysis}

\item{sobolconf}{the confidence level for bootstrap confidence intervals}

\item{nseeds}{number of seeds for this simulation design}

\item{precision}{number of digits for the decimal fraction of parameter values}
}
\value{
simdesign S4 class object
}
\description{
Add a sobol2007 simdesign to a nl object
}
\details{
This function creates a simdesign S4 class which can be added to a nl object.

Variables in the experiment variable list need to provide a numeric distribution with min, max and qfun (e.g. list(min=1, max=4, qfun="qunif")).

The sobol2007 simdesign uses the sensitivity package to set up a sobol2007 sensitivity analysis, including a simobject of class sobol and a input tibble for simulations.
For details on method specific sensitivity analysis function parameters see ?sobol2007
Finally, the function reports a simdesign object.
}
\examples{
\dontrun{
# Example for Wolf Sheep Predation model from NetLogo models library:
nl@simdesign <- simdesign_sobol2007(nl=nl,
samples=1000,
sobolnboot=100,
sobolconf=0.95,
nseeds=3,
precision=3)
}

}
