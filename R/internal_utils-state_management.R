# Utilities that help manage package state

#' Delete the data directory where seed log and debug log files are stored by
#' default
#'
#' ONLY intended for development use, e.g. to test starting from a fresh
#' installation
#' @keywords internal
.reset_data_dir <- function(yes_to_all = FALSE) {
  data_dir = .get_option('data_dir_location')
  if (!fs::dir_exists(data_dir)) {
    rlang::inform(glue::glue(
      "{data_dir} does not exist. Try reloading the package to rebuild. If you wish to change the location of the package data directory, set the `beacr.data_dir_location`global option."
    ))
    return(invisible())
  }
  if (yes_to_all) {
    fs::dir_delete(data_dir)
    # Log has been deleted, so errors crop up if trying to use
    # custom .inform
    rlang::inform(glue::glue("{data_dir} deleted"))
    return(NULL)
  }
  choice = .prompt_menu(
    c("Yes", "No, cancel"),
    title = glue::glue(
      "Will delete the following directory: {data_dir}"
    )
  )
  switch(
    choice,
    "1" = {
      if (fs::dir_exists(data_dir)) {
        fs::dir_delete(data_dir)
        # Log has been deleted, so errors crop up if trying to use
        # custom .inform
        rlang::inform(glue::glue("{data_dir} deleted"))
      }
    },
    "2" = {
      .inform("Cancelling...")
      invisible()
    }
  )
}
