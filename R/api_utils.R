# Utilities supporting the implementation logic for public exported functions
# (API)

#' Verify if any preregistration information was provided
#' Currently used in get_seed and verify_log
.preregistration_exists <- function(
  preregistration_identifier,
  preregistration_source
) {
  # Check nonempty identifier
  is_empty_list = (length(preregistration_identifier) == 0) ||
    (length(preregistration_source) == 0) #!_RETURN Formalize; this comes up when reading from json where the input is NULL; probably better to handle at the write stage than at the read stage
  no_id = .is_empty_string(preregistration_identifier)
  no_source = .is_empty_string(preregistration_source)
  if (no_id || no_source || is_empty_list) {
    prereg_id = force(preregistration_identifier %||% 'NULL')
    prereg_source = force(preregistration_source %||% 'NULL')
    .error(
      message = c(
        "During check for preregistration:",
        " " = "preregistration_identifier was {prereg_id}",
        " " = "preregistration_source was {prereg_source}"
      ),
      class = "beacr.PreregistrationNotFoundError"
    )
  }
  return(TRUE)
}

#' Convert and concatenate two values into a single raw bytes objec
.concatenate_hashes <- function(a, b, bits_a = NULL, bits_b = NULL) {
  .stopif(
    .any_is_null(a, b),
    c(
      "Attempted to concatenate one or more null hashes",
      "a is of type {typeof(a)}",
      "b is of type {typeof(b)}"
    )
  )
  a_is_raw = is.raw(a)
  b_is_raw = is.raw(b)
  if (length(a) == 0) {
    if (b_is_raw) {
      return(b)
    }
  }
  if (all(a_is_raw, b_is_raw)) {
    return(c(a, b))
  } else {
    if (!a_is_raw) {
      a = .to_raw(a, bits_a)
    }
    if (!b_is_raw) {
      b = .to_raw(b, bits_b)
    }
    return(c(a, b))
  }
}


#' Check for seed log in directory
.seed_log_exists <- function(dir_ = getwd(), seed_log_name = "seed_log.json") {
  dir_ = fs::path(dir_)
  if (!fs::is_dir(dir_) || !fs::dir_exists(dir_)) {
    .error(c(
      "Error when checking directory.",
      "Directory to check is a dir_? {fs::is_dir(dir_)",
      "Directory to check exists? {fs::dir_exists(dir_)}"
    ))
  }
  node_names = fs::path_file(fs::dir_ls(dir_))
  log_is_here = seed_log_name %in% node_names
  if (!log_is_here) {
    if ("beacr" %in% node_names) {
      beacr_subdir = fs::path(dir_, "beacr")
      subdir_node_names = fs::path_file(fs::dir_ls(beacr_subdir))
      log_is_in_beacr_subdir = seed_log_name %in% subdir_node_names
    }
  }
  return(log_is_here || log_is_in_beacr_subdir)
}
