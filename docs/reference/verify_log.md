# Verify the contents of a seed log are internally consistent

Verify the contents of a seed log are internally consistent

## Usage

``` r
verify_log(log_file, start_pulse_for_skiplist = NULL)
```

## Arguments

- log_file:

  Seed log file to use for verifying; when called as part of `get_seed`,
  this will automatically be passed via the `log_file` argument of that
  function. Useful if you wish to verify a log file other than the
  default, e.g. if you are testing multiple seeds and writing multiple
  log files as a result

- start_pulse_for_skiplist:

  To allow starting from a diff pulse than latest on chain, i.e. if a
  known diversion from protocol or infiltration occurred

## Details

Currently uses a hash table variable labelled `.beacons` that matches a
beacon string to the corresponding R6 object
