# Set the value of a `beacr`-specific global option

Setter that prepends my pkg namespace to global options. Allows
something like `.set_option(hash_length=512L)` without colliding with
another option from another pkg

## Usage

``` r
.set_option(...)
```
