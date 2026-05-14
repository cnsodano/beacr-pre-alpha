# # done = FALSE
# # cli::cli_progress_bar()
# # while (!done) {
# #   Sys.sleep(0.3)
# #   cli::cli_progress_message("step {step}")
# # }
# # print("hi")
# # library(httr2)
# # Custom format token that shows seconds per unit

# progress_with_spunit <- function(total, ...) {
#   # Track timing
#   start_time <- proc.time()[["elapsed"]]
#   units_done <- 0L

#   pb <- cli::cli_progress_bar(
#     total = total,
#     format = paste0(
#       "{cli::pb_bar} {cli::pb_current}/{cli::pb_total} | ",
#       "{pb_sec_per_unit} sec/unit | ",
#       "ETA: {cli::pb_eta}"
#     ),
#     format_done = paste0(
#       "{cli::pb_bar} {cli::pb_total}/{cli::pb_total} | ",
#       "Done in {cli::pb_elapsed}"
#     ),
#     .envir = parent.frame(),
#     ...
#   )

#   # Attach a custom updater that injects sec/unit into the bar
#   # by using `extra` list in cli_progress_update()
#   list(
#     bar = pb,
#     start = start_time,
#     update = function(set = NULL, inc = 1L) {
#       if (!is.null(set)) {
#         units_done <<- set
#       } else {
#         units_done <<- units_done + inc
#       }
#       elapsed <- proc.time()[["elapsed"]] - start_time
#       sec_per_u <- if (units_done > 0) {
#         round(elapsed / units_done, 3)
#       } else {
#         NA_real_
#       }
#       cli::cli_progress_update(
#         id = pb,
#         set = units_done,
#         extra = list(pb_sec_per_unit = sec_per_u),
#         .envir = parent.frame()
#       )
#     },
#     done = function() cli::cli_progress_done(id = pb, .envir = parent.frame())
#   )
# }
