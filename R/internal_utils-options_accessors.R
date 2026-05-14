# Utilities to get and set global options

#! _RETURN In future perhaps make this a R6 class that allows introspecting all available options and help pages for getters/setters to show their options, along with match.arg or some more centralized Enum scheme for validation.

#' Get the value of a `beacr`-specific global option
#'
#' Getter that prepends my pkg namespace to global options. Allows
#' something like `.get_option('hash_length')` without colliding
#' with another option from another pkg
.get_option <- function(name, default = NULL) {
  getOption(sprintf("beacr.%s", name), default = default)
}

#' Set the value of a `beacr`-specific global option
#'
#' Setter that prepends my pkg namespace to global options. Allows
#' something like `.set_option(hash_length=512L)` without colliding
#' with another option from another pkg
.set_option <- function(...) {
  args <- list(...)
  names(args) <- paste0("beacr.", names(args))
  do.call(options, args)
}

#' Get the options that need to be set for a specific Beacon to work
#'
#' Currently only used for readability in BeaconInterface; facilitates triaging
#' of option sources; user-passes options take priority (in the case of
#' experienced developers extending functionality, e.g.), then global options (
#' allowing workflows that use .Rprofile or other ways of setting global
#' options) and then falling back to package defaults.
#' @seealso [.get_beacon_json()]
.get_beacon_defaults <- function(beacon_name) {
  return(.get_beacon_json()[[beacon_name]])
}

#' Read the JSON file specifying default settings values for a specific Beacon
#'
#' @seealso [.get_beacon_defaults()]
.get_beacon_json <- function() {
  path <- system.file("extdata", "beacons.json", package = "beacr")
  if (identical(path, "")) {
    .error(
      "beacons.json was not found in the package extdata folder and thus default configuration values for the beacons cannot be read. Try to reinstall the package"
    )
  }
  data <- jsonlite::read_json(path)$beacons_table
  return(data)
}
