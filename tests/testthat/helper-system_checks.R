.on_windows <- function() {
  return(Sys.info()["sysname"] == "Windows")
}
