# Write a temporary msg to stdout that will be removed upon progressbar completion

Write a temporary msg to stdout that will be removed upon progressbar
completion

## Usage

``` r
.cli_progress_output(msg, ..., .envir = parent.frame())
```

## Details

Thin wrapper around cli::cli_progress_output that also logs explicitly.
Notably, it will not replace the progressbar when displaying
