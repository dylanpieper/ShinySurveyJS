% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/helper.R
\name{configure_shiny}
\alias{configure_shiny}
\title{Configure Shiny App Settings}
\usage{
configure_shiny(..., type_handlers = list())
}
\arguments{
\item{...}{Named arguments corresponding to Shiny options. Names will be prefixed with 'shiny.'}

\item{type_handlers}{Named list of functions to process specific options. Default handlers
are provided for numeric, logical, and character values.}
}
\value{
NULL (invisibly). Sets global options for Shiny.
}
\description{
Configure Shiny App Settings
}
\examples{
\dontrun{
configure_shiny(
  host = "0.0.0.0",
  port = 3838,
  sanitize_errors = TRUE,
  autoreload = FALSE
)
}
}
