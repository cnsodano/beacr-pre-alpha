#' Read the debug log
#'
#' Opens a new R window that allows reading the log file using the built-in
#' `file.show()` R function, starting from the bottom (most recently logged
#' messages). If no log file path is passed, will search for log files in the
#' default logging directory
#'
#' @param log_file The custom log file path you wish to read. If
#' no file is passed, a prompt menu will appear asking which log in the
#' default log file directory you wish to read
#'
#' @seealso [file.show()]
#' @export
read_logs <- function(log_file = NULL) {
  if (is.null(log_file)) {
    .inform(c(
      "!" = "No log file was provided, searching in the default log directory {.get_option('log_dir_location')}"
    ))
  } else {
    rlang::try_fetch(
      {
        file.show(path = log_file, title = "Log: ")
      },
      warning = function(w) {
        .rethrow_if_not("does not exist", w)
        .error(
          "Attempted to read log file at {log_file} but no file exists at that path."
        )
      }
    )
  }
  log_dir = .get_option("log_dir_location")
  log_files = fs::dir_ls(.get_option("log_dir_location"), glob = "*.log")
  choice = .prompt_menu(
    choices = log_files,
    title = "Which log would you like to view?"
  )
  .success("Selected {choice}")
  .inform(c(
    "!" = "Showing file {log_files[choice]} in default R file viewer\nYou may have to look for newly opened windows (the window may not pop up automatically)"
  ))
  file.show(path = log_files[choice], title = "Log: ")
}
