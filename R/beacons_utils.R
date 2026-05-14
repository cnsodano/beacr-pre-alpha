# Utilities supporting Beacon instantiation and methods

# Hash table to allow recreating Beacon object from log without having to
# serialize the entire object (char name => Beacon object)
#!_RETURN make proper factojry for beacons to allow pulling from settings
.beacons = new.env(hash = TRUE, parent = emptyenv())
.beacons$"NISTBeacon" = NISTBeacon


.resolve_option <- function(...) {
  args = list(...)
  if (!.is_called_from_r6_method(search_up_frames_recursively = TRUE)) {
    stopifnot(
      "When calling .resolve_option outside of a R6 class (e.g. a Beacon), you must explicitly pass 'defaults' into the arglist as it cannot infer the Beacon-specific defaults to use when resolving options to set",
      "defaults" %in% names(args)
    )
  } else {
    beacon_class = .get_ancestor_r6_obj_classname()
    defaults = .get_beacon_defaults(beacon_class)
  }
  for (name in names(defaults)) {
    # Prioriy goes to the user-passed value, then to the globally
    # set option if there is any, then to the package's default
    #
    # In theory this allows initializing >1 Beacon objects with
    # differing settings for testing or combining beacons
    self[[name]] = .arg_passed(name, args) %||%
      .get_option(paste0(
        class(self)[1],
        '.',
        name,
        collapse = ""
      )) %||%
      defaults[[name]]
  }
}

.is_called_from_r6_method <- function(search_up_frames_recursively = FALSE) {
  caller_env <- parent.frame()
  if (
    exists("self", where = caller_env, inherits = search_up_frames_recursively)
  ) {
    self_obj <- get(
      "self",
      envir = caller_env,
      inherits = search_up_frames_recursively
    )
    return(inherits(self_obj, "R6"))
  }

  return(FALSE)
}

.get_ancestor_r6_obj_classname <- function() {
  caller_env = parent.frame()
  if (
    exists("self", where = caller_env, inherits = TRUE) # Inherits=TRUE will search up recursively
  ) {
    self_obj = get(
      "self",
      envir = caller_env,
      inherits = TRUE
    )
    return(class(self_obj)[1])
  }
  return(NULL)
}

#!_RETURN
# #' Convert an integer number of seconds into the year/month/day/minute dateparts
# #' it represents
# #'
# #' @details Currently used to construct a warning when verifying a historical
# #' pulse via skiplist based on how long ago the pulse was issued and to count
# #' the number of API calls that may be needed
# .seconds_to_dateparts <- function(secs) {
#   period = lubridate::as.period(seconds(secs))
#   return(c(
#     years = lubridate::year(period),
#     months = lubridate::month(period),
#     days = lubridate::day(period),
#     minutes = lubridate::minute(period)
#   ))
# }
