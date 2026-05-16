#' Find where the information needed to verify the seeds acquired by `get_seed`
#' is being written to by default
#'@export
where_is_seed_log <- function() {
  data_dir = .get_option("data_dir_location")
  files = fs::dir_ls(data_dir)
  default_seed_log_path = fs::path(data_dir, "seed_log.json")
  if (default_seed_log_path %in% files) {
    .inform(c(
      "The default seed log being used by `get_seed()` when no `log_file` argument is passed is:",
      " " = "{default_seed_log_path}"
    ))
  } else {
    .inform(c(
      "No seed log was found in the default beacr data directory at:",
      " " = "{data_dir}",
      "Likely culprits are:",
      "*" = "`get_seed()` has not be called yet and no seed_log has been written",
      "*" = "`reset_seed_log()` has been called and deleted the previous seed_log",
      "*" = "`get_seed()` has been called but with a custom `log_file` argument, causing the seed_log to be written to a different location than the default beacr data directory"
    ))
  }
  invisible()
}
