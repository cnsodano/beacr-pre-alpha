# Helper for visualizing the raw bit form of a byte vector

Note that R's rawToBits(...) function prints out bits in little-endian
order by default and since it uses the atomic 'bytes' data type for
output every bit will be represented as a hex byte, that is either 00 or
01. This is confusing, so I use as.integer to convert the bytes into a
single number (00=\>0, 01=\>1) and rev() to turn from little-endian to
big-endian by default

## Usage

``` r
.as_bits(raw_value, bits, endian = "big")
```
