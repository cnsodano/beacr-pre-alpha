# Read the debug log

Opens a new R window that allows reading the log file using the built-in
[`file.show()`](https://rdrr.io/r/base/file.show.html) R function,
starting from the bottom (most recently logged messages). If no log file
path is passed, will search for log files in the default logging
directory

## Usage

``` r
read_logs(log_file = NULL)
```

## Arguments

- log_file:

  The custom log file path you wish to read. If no file is passed, a
  prompt menu will appear asking which log in the default log file
  directory you wish to read

## See also

[`file.show()`](https://rdrr.io/r/base/file.show.html)
