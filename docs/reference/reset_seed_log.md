# Remove stale seed logs to allow acquiring and logging a new random value

`reset_seed_log()` removes `*.json` files from the current seed_log
directory, as found from getOption("beacr.data_dir_location").
Alternatively, if you passed custom file or directory locations when
creating the seed log, use the parameters of `reset_seed_log()` to
target and delete those custom paths.

## Usage

``` r
reset_seed_log(
  purge_files = c(),
  purge_directory = NULL,
  purge_all = FALSE,
  yes_to_all = FALSE
)
```

## Arguments

- purge_files:

  A character vector of file paths to delete. If you use custom log file
  paths then you will need to pass this, as by default only
  seed_log.json files in the default `<WORKSPACE>/beacr/` folder will be
  deleted otherwise

- purge_directory:

  A path to the directory where you hold your seed logs, if different
  from the default

- purge_all:

  Boolean. Whether to delete all .json files in the target directory or
  not. If no files are specified in purge_files, this will default to
  TRUE \#!\_RETURN In future, allow perhaps regexp filtering of files to
  keep/delete?

- yes_to_all:

  Boolean. Whether to skip the menu that allows you to review and
  confirm choices before deleting files. Useful for automated workflows
  and testing

## Details

If `reset_seed_log()` is not called, every call to `get_seed(...)` that
uses the same `log_file` argument after the first call will read from
the same file and reproduce the same seed. If you want to get a new
seed, you MUST call `reset_seed_log()`
