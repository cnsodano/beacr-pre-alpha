#' title
#'
#' desc
#'
#' @export
reset_seed_log <- function(
  purge_files = c(),
  purge_directory = NULL,
  purge_all = FALSE,
  yes_to_all = FALSE
) {
  dir_to_purge = purge_directory %||% .get_option('data_dir_location')
  #!_RETURN handle if only passing files and they don't exist
  print(glue::glue("dir {fs::dir_exists(dir_to_purge)}"))
  if (!fs::dir_exists(dir_to_purge)) {
    invisible()
    browser()
  }
  if (purge_all) {
    if (!yes_to_all) {
      choice = .prompt_menu(
        c("Yes", "No, cancel"),
        title = sprintf(
          "You are about to delete all files from the following directory: %s\nAre you sure?",
          dir_to_purge
        )
      )
      switch(
        choice,
        "1" = {
          .inform(c("!" = "Deleting all files in {dir_to_purge}"))
          fs::file_delete(fs::dir_ls(dir_to_purge))
        },
        "2" = {
          .inform(c("!" = "Cancelling..."))
          invisible()
        }
      )
    } else {
      .inform(c("!" = "Deleting all files in {dir_to_purge}"))
      fs::file_delete(fs::dir_ls(dir_to_purge))
    }
  } else {
    if (length(purge_files) != 0) {
      if (!yes_to_all) {
        choice = .prompt_menu(
          c("Yes", "No, cancel"),
          title = paste(
            sprintf(
              "You are about to delete the following files: \n%s\nAre you sure?",
              purge_files
            ),
            collapse = "\n"
          )
        )
        switch(
          choice,
          "1" = {
            .inform(c("!" = "Deleting all files chosen"))
            for (file in purge_files) {
              fs::file_delete(file)
            }
          },
          "2" = {
            .inform(c("!" = "Cancelling..."))
            invisible()
          }
        )
      } else {
        .inform(c("!" = "Deleting all files chosen"))
        for (file in purge_files) {
          fs::file_delete(file)
        }
      }
    } else {
      if (!yes_to_all) {
        choice = .prompt_menu(
          c("Yes", "No, cancel"),
          title = sprintf(
            "No file or directory was passed, do you want to delete the files in the default directory (%s)?",
            dir_to_purge
          )
        )
        switch(
          choice,
          "1" = {
            .inform(c("!" = "Deleting all files in {dir_to_purge}"))
            fs::file_delete(fs::dir_ls(dir_to_purge))
          },
          "2" = {
            .inform(c("!" = "Cancelling..."))
            invisible()
          }
        )
      } else {
        .inform(c("!" = "Deleting all files in {dir_to_purge}"))
        fs::file_delete(fs::dir_ls(dir_to_purge))
      }
    }
  }
}
