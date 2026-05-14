# Utilities for logging, including wrappers around rlang conditions that allow
# simultaneous logging and handling of those conditions (i.e. a try_fetch block
# will log that the condition was thrown even if it was caught)
#
#! _RETURN This whole file is a bunch of copy paste that should be formalized
#! into one factory function or OO interface

.parse_log_level <- function(level) {
  levels <- list(
    TRACE = logger::TRACE,
    DEBUG = logger::DEBUG,
    INFO = logger::INFO,
    WARN = logger::WARN,
    ERROR = logger::ERROR,
    FATAL = logger::FATAL
  )

  key <- toupper(trimws(level))

  if (!key %in% names(levels)) {
    rlang::abort(
      paste0(
        "Unknown log level: '",
        level,
        "'. Must be one of: ",
        paste(names(levels), collapse = ", ")
      )
    )
  }

  return(levels[[key]])
}

#' Set up logger for the package
.setup_logging <- function(pkgname) {
  # Set up the logger::log_appender for this package's namespace (so
  # no conflict with other loaded packages' logger)
  log_appender_ = NULL

  # Where is the log file being written to?
  dir_opt = .get_option("log_dir_location", default = "")
  switch(
    dir_opt,
    "OS-default" = {
      log_dir_location = fs::path(tools::R_user_dir("beacr", which = "data"))
    },
    "working_directory" = {
      log_dir_location = fs::path(getwd(), "beacr")
    },
    {
      log_dir_location = fs::path(dir_opt) # Already set OR user-customized
    }
  )
  .set_option(log_dir_location = log_dir_location)

  log_file = fs::path(log_dir_location, "beacr_debug.log")

  # Set which log appender; log to file? log to console? both?
  log_appender_type = .get_option("log_appender_type")
  switch(
    log_appender_type,
    "tee" = {
      # Adapted from package source example: https://github.com/daroczig/logger/blob/main/R/appenders.R
      appender_tee <- function(
        file,
        append = TRUE,
        max_lines = Inf,
        max_bytes = Inf,
        max_files = 1L
      ) {
        force(file)
        force(append)
        force(max_lines)
        force(max_bytes)
        force(max_files)
        structure(
          function(lines) {
            if (needs_stdout()) {
              appender_stdout(lines)
            } else {
              appender_console(lines)
            }
            .appender_file <- function(lines) {
              clean <- cli::ansi_strip(lines)
              cat(clean, file = log_file, append = TRUE, sep = "\n")
              cat("\n", file = log_file, append = TRUE, sep = "\n")
            }
            .appender_file(file)(lines) # . at beginning distinguishes my internal function from
          },
          generator = deparse(match.call())
        )
      }
      log_appender_ = logger::appender_tee(log_file)
    },
    "console" = {
      log_appender_ = logger::appender_console
    },
    "file" = {
      .appender_file <- function(lines) {
        clean <- cli::ansi_strip(lines)
        cat(clean, file = log_file, append = TRUE, sep = "\n")
        cat("\n", file = log_file, append = TRUE, sep = "\n")
      }
      log_appender_ = .appender_file
      attr(log_appender_, "generator") <- quote(log_appender_())
      # logger::appender_file(log_file)
    }
    # }
  )
  logger::log_appender(log_appender_, namespace = pkgname)
  if (log_appender_type %in% c("tee", "file")) {
    rlang::try_fetch(
      {
        dir.create(log_dir_location, recursive = TRUE, showWarnings = TRUE)
        .inform("beacr: Creating debug log folder at: {log_dir_location}")
        #!_RETURN Alert to current log level and vignete re: logging
      },
      warning = function(w) {
        .rethrow_if_not(condition_message = "already exists", w)
        .inform("beacr: Debug logs are being written to: {log_dir_location}")
      }
    )
  }

  # Set the threshold below which messages are silently dropped entirely.
  # Messages below this level won't even reach the appender.
  log_level_str = .get_option("log_level" %||% logger::DEBUG)
  log_level_logger_obj = .parse_log_level(log_level_str)
  logger::log_threshold(level = log_level_logger_obj, namespace = pkgname)

  # Set custom log layout
  logger::log_layout(
    logger::layout_glue_generator(
      format = "namespace: {ns} || Log signal type: {level} \n[{format(time, '%Y-%m-%d %H:%M:%S')}]: {msg}"
    ),
    namespace = pkgname
  )
}

.stopifnot <- function(expr, message, ...) {
  if (expr) {
    invisible()
  } else {
    .error(message, ..., .topcall = sys.call(-1), .topenv = parent.frame())
  }
}

.stopif <- function(expr, message, ...) {
  if (expr) {
    .error(message, ..., .topcall = sys.call(-1), .topenv = parent.frame())
  } else {
    invisible()
  }
}

.vglue <- function(x, .envir = parent.frame(), strip_ANSI_codes = FALSE) {
  result <- vapply(
    x,
    function(item) {
      res = as.character(glue::glue(item, .envir = .envir))
      return(res)
    },
    character(1)
  )
  if (is.null(names(x))) {
    return(unname(result))
  } else {
    return(result)
  }
}

## convenient variable interpolation, etc
.success <- function(
  message,
  ...,
  footer = "",
  .ns = "beacr",
  .topcall = sys.call(-1),
  .topenv = parent.frame(),
  strictness = NULL
) {
  if (length(message) == 1) {
    message_ = c("v" = message)
  } else {
    message_ = message
  }
  message_ = .add_newline(message_)
  strictness = strictness %||% .get_option("strictness")
  cnd = .resolve_condition_to_throw("success", strictness)
  cond = cnd(
    message = message_,
    class = "beacr.success",
    ...,
    use_cli_format = TRUE
  )

  # Log the full formatted message
  logger::log_info(
    paste0(
      "|| .success ||  strictness:",
      strictness,
      " || ",
      format(cond),
      "\nCalling rlang::inform..."
    ),
    namespace = .ns,
    .topcall = .topcall,
    .topenv = .topenv
  )

  # Now throw the condition
  rlang::inform(
    message = .vglue(message_, .envir = .topenv),
    ...,
    class = "beacr.success",
    call = .topcall
  )
}
.nonstopping_fail <- function(
  message,
  footer = "",
  ...,
  .ns = "beacr",
  .topcall = sys.call(-1),
  .topenv = parent.frame(),
  strictness = NULL
) {
  if (length(message) == 1) {
    message = c("x" = message)
  } else {
    message = message
  }

  strictness = strictness %||% .get_option("strictness")
  message = .add_newline(message)
  cnd = .resolve_condition_to_throw("nonstopping_fail", strictness)
  cond = cnd(
    message = message,
    class = "beacr.nonstopping_fail",
    ...,
    use_cli_format = TRUE
  )

  # Log the full formatted message
  logger::log_error(
    paste0(
      "|| .nonstopping_fail ||  strictness:",
      strictness,
      " || ",
      format(cond),
      "\nCalling rlang::inform..."
    ),
    namespace = .ns,
    .topcall = .topcall,
    .topenv = .topenv
  )

  # Now throw the condition
  .inform_spaced(
    message = .vglue(message, .envir = .topenv),
    class = "beacr.nonstopping_fail",
    ...,
    call = .topcall
  )
}
.resolve_condition_to_throw <- function(
  base_condition,
  strictness
) {
  # fn_* are passed directly to function and should override global options
  switch(
    base_condition,
    "warn" = {
      if (strictness >= 1) {
        return(rlang::error_cnd)
      } else {
        return(rlang::warning_cnd)
      }
    },
    "abort" = {
      return(rlang::error_cnd)
    },
    "inform" = {
      if (strictness >= 1) {
        return(rlang::warning_cnd)
      } else {
        return(rlang::message_cnd)
      }
    },
    "debug" = {
      if (strictness > 1) {
        return(rlang::warning_cnd)
      } else {
        return(rlang::message_cnd)
      }
    },
    "nonstopping_fail" = {
      if (strictness > 1) {
        return(rlang::error_cnd)
      } else {
        return(rlang::message_cnd)
      }
    },
    "success" = {
      if (strictness > 1) {
        return(rlang::warning_cnd)
      } else {
        return(rlang::message_cnd)
      }
    }
  )
}
.warn <- function(
  message,
  ...,
  footer = "",
  .ns = "beacr",
  .topcall = sys.call(-1),
  .topenv = parent.frame(),
  strictness = NULL
) {
  strictness = strictness %||% .get_option("strictness")

  message = .add_newline(message)

  cnd = .resolve_condition_to_throw("warn", strictness)
  cond = cnd(
    message = .vglue(
      message,
      .envir = .topenv
    ),
    ...,
    use_cli_format = TRUE
  )

  # Log the full formatted message
  logger::log_warn(
    paste0(
      "|| .warn || strictness:",
      strictness,
      " || ",
      format(cond),
      "\nCalling rlang::warn..."
    ),
    namespace = .ns,
    .topcall = .topcall,
    .topenv = .topenv
  )

  # Now throw the condition
  # Locally set warn option to 1 so that warnings are immediately pushed to user instead of queued and sent in aggregate

  withr::with_options(list(warn = 1), {
    rlang::cnd_signal(cnd(
      message = .vglue(message, .envir = .topenv),
      ...,
      call = .topcall
    ))
  })
}
.resolve_logger <- function(class_) {
  switch(
    class_,
    "message" = {
      return(logger::log_info)
    },
    "warning" = {
      return(logger::log_warn)
    },
    "error" = {
      return(logger::log_error)
    },
    {
      return(logger::log_info)
    }
  )
}
.get_real_caller <- function(as_call = FALSE) {
  calls = sys.calls()

  # Names of frames to skip over
  internal_names = c(
    ".get_real_caller",
    "handlers[[1L]]",
    "tryCatch",
    "function (cnd) ",
    "tryCatchOne",
    "cnd_signal",
    "tryCatchList",
    "try_fetch",
    "signal_abort",
    "rlang::signal",
    "signalCondition",
    "withCallingHandlers",
    ".signal"
  )
  for (i in rev(seq_along(calls))) {
    fn_name = tryCatch(
      deparse(calls[[i]][[1]])[[1]],
      error = function(e) ""
    )
    if (!fn_name %in% internal_names) {
      if (as_call) {
        return(calls[[i]])
      } else {
        if (i < length(calls)) {
          return(glue::glue("Exception handler beginning from: {fn_name}"))
        }
        return(fn_name)
      }
    }
  }

  return("<unknown>")
}
.error <- function(
  message,
  ...,
  footer = "",
  .ns = "beacr",
  .topcall = sys.call(-1),
  .topenv = parent.frame(),
  strictness = NULL
) {
  # Build the full rlang error condition without throwing it yet
  message = .add_newline(message)

  strictness = strictness %||% .get_option("strictness")
  cond = rlang::error_cnd(
    message = .vglue(message, .envir = .topenv),
    use_cli_format = TRUE,
    ...
  )

  # Log the full formatted message
  logger::log_error(
    paste0(
      "|| .error || strictness:",
      strictness,
      " || ",
      format(cond),
      "\nCalling rlang::abort..."
    ),
    namespace = .ns,
    .topcall = .topcall,
    .topenv = .topenv
  )

  # Now throw the condition
  rlang::abort(
    message = .vglue(message, .envir = .topenv),
    ...,
    call = .topcall
  )
}
.add_newline <- function(message) {
  nms <- names(message)
  if (length(message) > 1) {
    message[-1] = paste0(message[-1], '\n\n')
  } else {
    message = paste0(message, '\n\n')
  }
  names(message) = nms
  return(message)
}
.inform <- function(
  message,
  ...,
  # footer = "",
  .ns = "beacr",
  .topcall = sys.call(-1),
  .topenv = parent.frame(),
  strictness = NULL
) {
  # Build the full rlang error condition without throwing it yet
  message = .add_newline(message)
  strictness = strictness %||% .get_option("strictness")
  cnd = .resolve_condition_to_throw("inform", strictness)
  cond = cnd(
    message = message,
    use_cli_format = TRUE,
    ...
  )
  # Log the full formatted message
  logger::log_info(
    paste0(
      "|| .inform || strictness:",
      strictness,
      " || ",
      format(cond),
      "\nCalling rlang::inform..."
    ),
    namespace = .ns,
    .topcall = .topcall,
    .topenv = .topenv
  )

  # Now throw the condition
  .inform_spaced(
    message = .vglue(message, .envir = .topenv),
    ...,
    call = .topcall
  )
}
.debug <- function(
  message,
  ...,
  footer = "",
  .ns = "beacr",
  .topcall = sys.call(-1),
  .topenv = parent.frame(),
  strictness = NULL
) {
  message = .add_newline(message)
  strictness = strictness %||% .get_option("strictness")
  cnd = .resolve_condition_to_throw("debug", strictness)
  cond = cnd(
    message = message,
    class = 'beacr.debug',
    use_cli_format = TRUE,
    ...
  )

  # Log the full formatted message
  logger::log_debug(
    paste0(
      "|| .debug ||  strictness:",
      strictness,
      " || ",
      format(cond),
      "\nCalling rlang::inform..."
    ),
    namespace = .ns,
    .topcall = .topcall,
    .topenv = .topenv
  )

  # Now throw the condition
  rlang::signal(
    message = .vglue(message, .envir = .topenv),
    ...,
    class = "beacr.debug",
    call = .topcall
  )
}
.rethrow_if_not <- function(condition_message, signal) {
  if (!grepl(condition_message, conditionMessage(signal))) {
    rlang::cnd_signal(signal) # re-throw non-matching signals (errors, warnings, etc)
  }
  invisible()
}


.setup_data_dir <- function() {
  dir_opt = .get_option("data_dir_location", default = "")
  switch(
    dir_opt,
    "OS-default" = {
      data_dir = fs::path(tools::R_user_dir("beacr", which = "data"))
    },
    "working_directory" = {
      data_dir = fs::path(getwd(), "beacr")
    },
    {
      data_dir = fs::path(dir_opt) # Already set OR user-customized
    }
  )
  .set_option(data_dir_location = data_dir)
  # warned = FALSE
  rlang::try_fetch(
    {
      dir.create(data_dir, recursive = TRUE, showWarnings = TRUE)
      .inform(
        "`beacr` loaded. Seed log directory was set by default to be: {data_dir}"
      )
    },
    warning = function(w) {
      .rethrow_if_not(condition_message = "already exists", w)
      .inform("beacr: Seed log default location is: {data_dir}")
    }
  )
  # withCallingHandlers(
  #   {},
  #   warning = function(w) {
  #     warned <<- TRUE # Note super-assignment
  #     if (grepl("already exists", conditionMessage(w))) {
  #       message(sprintf(
  #         "`beacr` loaded. Seed log default location is: %s",
  #         data_dir
  #       ))
  #       invokeRestart("muffleWarning")
  #     }
  #     # If some other warning, propagate normally
  #   }
  # )
  # if (!warned) {
  #   message(sprintf(
  #     "`beacr` loaded. Seed log directory was set by default to be: %s",
  #     data_dir
  #   ))
  # }
  return(data_dir)
}

#' Write a temporary msg to stdout that will be removed upon progressbar
#' completion
#'
#' @details Thin wrapper around cli::cli_progress_output that also logs
#' explicitly. Notably, it will not replace the progressbar when displaying
.cli_progress_output <- function(msg, ..., .envir = parent.frame()) {
  .debug(
    message = c("Calling from .cli_progress_output:", msg),
    .topenv = .envir
  )
  rlang::try_fetch(
    {
      cli::cli_progress_output(msg, ..., .envir = .envir)
    },
    error = function(e) {
      .rethrow_if_not("Cannot find current progress bar", e)
      invisible()
    }
  )
}

.inform_spaced <- function(message, ..., call) {
  msg = c(message, "")
  cli::cli_inform(message = msg, ..., call = call)
  invisible()
}
