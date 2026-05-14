# Convenience functions sprinkled throughout the codebase where useful

#' Check if there are any nulls in a list of objects
.any_is_null <- function(...) {
  ls = list(...)
  return(any(vapply(ls, is.null, logical(1))))
}

.arg_passed <- function(name, args) {
  if (name %in% names(args)) {
    return(args[[name]])
  } else {
    return(NULL)
  }
}

#' Thin wrapper around `menu` to allow mocking in tests as mocking `menu` is
#' unsupported`
.prompt_menu <- function(choices, title) {
  menu(choices, title = title)
}

.is_empty_string <- function(str_) {
  return(is.null(str_) || identical(str_, ""))
}
