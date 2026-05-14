# Get the value of a `beacr`-specific global option

Getter that prepends my pkg namespace to global options. Allows
something like `.get_option('hash_length')` without colliding with
another option from another pkg

## Usage

``` r
.get_option(name, default = NULL)
```
