# Utilities for debugging during package development

#' Print out NIST UNIX timestamps (milliseconds since epoch) in a readable way
.printt <- function(msPosixtime) {
  print(format(
    msPosixtime,
    scientific = FALSE,
    nsmall = 20,
    drop0trailing = TRUE
  ))
}
