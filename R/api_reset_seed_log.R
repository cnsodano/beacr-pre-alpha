#' Remove stale seed logs to allow acquiring and logging a new random value
#'
#' `reset_seed_log()` removes `*.json` files from the current seed_log directory, as found from getOption("beacr.data_dir_location"). Alternatively, if you passed custom file or directory locations when creating the seed log, use the parameters of `reset_seed_log()` to target and delete those custom paths.
#'
#' If `reset_seed_log()` is not called, every call to `get_seed(...)` that uses the same `log_file` argument after the first call will read from the same file and reproduce the same seed. If you want to get a new seed, you MUST call `reset_seed_log()`
#'
#' @param purge_files A character vector of file paths to delete. If you use custom log file paths then you will need to pass this, as by default only seed_log.json files in the default `<WORKSPACE>/beacr/` folder will be deleted otherwise
#' @param purge_directory A path to the directory where you hold your seed logs, if different from the default
#' @param purge_all Boolean. Whether to delete all .json files in the target directory or not. If no files are specified in purge_files, this will default to TRUE
#' #!_RETURN In future, allow perhaps regexp filtering of files to keep/delete?
#' @param yes_to_all Boolean. Whether to skip the menu that allows you to review and confirm choices before deleting files. Useful for automated workflows and testing
#' @export
reset_seed_log <- function(
  purge_files = c(),
  purge_directory = NULL,
  purge_all = FALSE,
  yes_to_all = FALSE
) {
  dir_to_purge = purge_directory %||% .get_option('data_dir_location')
  #!_RETURN handle if only passing files and they don't exist
  if (!fs::dir_exists(dir_to_purge)) {
    invisible()
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
        .inform(c("!" = "Deleting all JSON files chosen"))
        for (file in purge_files) {
          .delete_json(file)
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

#' Delete a file if it is a JSON file type
.delete_json <- function(path) {
  path = fs::path(path)
  if (identical(fs::path_ext(path), "json")) {
    fs::file_delete(path)
  } else {
    .inform(
      c(
        "Error while trying to delete {path}:",
        " " = "Path is not a path to a JSON file. `reset_seed_log()` should be used to delete JSON logs only. Continuing without deleting..."
      ),
      class = "beacr.IncorrectFileTypeError"
    )
  }
}


#' Delete every JSON file in a directory
.delete_json_in_dir <- function(dir_path) {
  for (file in fs::dir_ls(dir_path)) {
    .delete_json(file)
  }
}
