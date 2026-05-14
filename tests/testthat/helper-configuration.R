#' create and configure a temporary directory to execute test
#' code in
.with_tempdir <- function(code) {
  .test_path = fs::path(
    rprojroot::find_root(rprojroot::is_r_package),
    "tests",
    "testthat"
  ) # To set the test_path to this outer directory; useful when trying to use vcr
  withr::with_tempdir({
    # configure to treat temp dir as proj root
    temp_beacr_dir = fs::path(getwd(), "beacr")
    dir.create(temp_beacr_dir)
    local_mocked_bindings(
      test_path = function(...) {
        return(do.call(
          \(...) {
            as.character(fs::path(...))
          },
          list(.test_path, ...)
        ))
      },
      .package = 'testthat'
    )
    assertthat::assert_that(!.seed_log_exists())

    withr::local_options(
      beacr.data_dir_location = temp_beacr_dir,
      beacr.log_dir_location = temp_beacr_dir
    )
    eval(code)
  })
}


#' Recreate an environment where the package has already been loaded
#' and a data directory has been created for the seed_log, debug log, etc
#'
#' Used for testing
.setup_second_load <- function() {
  .reset_data_dir(yes_to_all = TRUE)
  callr::r(
    func = function() {
      devtools::load_all() #!_RETURN In future, update to load not from source
    }
  )
  invisible()
}

#' Setup fixture for preregistration tests where a seed is requested with a pre-set preregistration file
#' @param env_vars_used This is merely a flag for devs to be able to tell which variables not present in the test code are available in the test code env, so nothing seems like a 'magic variable'
.with_prereg <- function(code, env_vars_used) {
  .with_tempdir({
    ## Create seed log by first call, capturing messages

    # Corresponding to slides for a talk I gave at PYMS Summer Symposium 2025
    prereg_id = "https://osf.io/mbcw5/files/yahfc"
    msgs = capture_messages({
      seedA = get_seed(
        preregistration_identifier = prereg_id,
        preregistration_source = "OSF"
      )
    })
    env = new.env(parent = parent.frame())
    env$msgs = msgs
    env$seed = seed
    eval(code, envir = env)
  })
}
