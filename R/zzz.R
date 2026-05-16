# Note that this file is named zzz by convention to ensure it runs last during
# loading

#' To store record of any changes that were made during loading to later revert
#' on unloading
#' @noRd
.pkg_env <- new.env(parent = emptyenv())

#' Hook to run when loading the package.
#'
#' Covers initialization steps such as building the data directory
#' @keywords internal
.onLoad <- function(libname, pkgname) {
  pkgname = "beacr"
  flag_file <- file.path(
    tools::R_user_dir(pkgname, which = "data"),
    ".welcomed"
  )
  if (!fs::file_exists(flag_file)) {
    packageStartupMessage(
      "Welcome to `",
      pkgname,
      "`! This message appears only once.\n",
      "Visit https://cnsodano.github.io/beacr-pre-alpha/ to learn more about how to use `beacr` and access in-depth documentation. You can also read the vignettes that explain common use cases.\n",
      "A good place to get started is by executing `vignette('beacr')` in your R console.\n",
      "If you want to learn more, check out other vignettes with `browseVignettes(package='beacr')`\n"
    )
    # Create the flag file so the message never shows again
    dir.create(dirname(flag_file), recursive = TRUE, showWarnings = FALSE)
    file.create(flag_file)
  }
  defaults_path <- system.file(
    "extdata",
    "package_settings.json",
    package = pkgname
  )
  defaults <- jsonlite::read_json(defaults_path)
  .load_settings(defaults, .pkg_env)

  # Setup logger, allowing for user override of log location, log appender, etc
  .setup_logging(pkgname = pkgname)

  # Create package-specific data directory for storing seeding logs
  data_dir = .setup_data_dir()

  .inform("beacr fully loaded!")
  invisible()
}

.load_settings <- function(defaults, pkgenv) {
  op <- options()
  names(defaults) <- paste0("beacr.", names(defaults))

  # Only set options that haven't already been set by the user
  toset <- !(names(defaults) %in% names(op))

  # Track only what we actually set
  .pkg_env$options_that_were_set <- names(defaults[toset])

  if (any(toset)) {
    options(defaults[toset])
  }
}
.onUnload <- function(libpath) {
  if (length(.pkg_env$options_that_were_set) > 0) {
    toremove <- setNames(
      vector("list", length(.pkg_env$options_that_were_set)),
      .pkg_env$options_that_were_set
    )
    options(toremove)
  }

  #! _RETURN Ensure logger cleans up as expected
  invisible()
}
