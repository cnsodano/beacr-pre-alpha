# Verify the contents of a seed log are internally consistent

Verify the contents of a seed log are internally consistent

## Usage

``` r
verify_log(log_file, start_pulse_for_skiplist = NULL)
```

## Arguments

- start_pulse_for_skiplist:

  To allow starting from a diff pulse than latest on chain, i.e. if a
  known diversion from protocol or infiltration occurred

## Details

Currently uses a hash table variable labelled `.beacons` that matches a
beacon string to the corresponding R6 object
