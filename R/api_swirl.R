#' Mix together the output of multiple randomness beacons to produce a random
#' number robust to protocol deviations from any one beacon
#'
#' Currently this is a placeholder; when called it will perform the exact same behavior as [get_seed]. In the future when multiple beacons are implemented, this function will combine multiple beacons together.
#' @seealso [get_seed]
#' @export
swirl <- function(...) {
  return(get_seed(...))
}
