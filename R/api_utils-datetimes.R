# Utilities that help with wrangling timestamp and datetime objects

#' Convert from R's POSIXct data type to the time encoding used by the
#' NISTBeacon, namely **milliseconds** since epoch
#' @seealso [.dt_to_ms]
.posix_to_NIST_UNIX <- function(posix_time) {
  return(.dt_to_ms(posix_time))
}

#' Converts a string return value from an API that represents a timestamp
#' into a timestamp integer in the format expected by the NISTBeacon; namely,
#' milliseconds since epoch
.timeStamp_to_unix_time <- function(timeStamp, round = FALSE) {
  return(.dt_to_ms(lubridate::as_datetime(timeStamp)))
}

.ms_to_dt <- function(ms) {
  return(lubridate::as_datetime(floor(as.numeric(ms) / 1000)))
}

.dt_to_ms <- function(dt) {
  return(as.integer(dt) * 1000)
}
