# Dispatcher for conversion to atomic raw byte vector type

Handle multiple possible raw data representations and convert them to
the base R type. Offers extensibility for Beacons or other randomness
ingest sources that represent binary data in nonstandard ways.

## Usage

``` r
.to_raw(value, bits)
```

## Arguments

- value:

  The value to be converted

- bits:

  The number of bits the output should have. This is important for
  validation but also detecting which conversion type to use; a string
  of 0's and 1's could be representing either binary or hex, so knowing
  how many bits it's supposed to represent is important in that edge
  case.
