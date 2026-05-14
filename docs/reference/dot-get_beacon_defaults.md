# Get the options that need to be set for a specific Beacon to work

Currently only used for readability in BeaconInterface; facilitates
triaging of option sources; user-passes options take priority (in the
case of experienced developers extending functionality, e.g.), then
global options ( allowing workflows that use .Rprofile or other ways of
setting global options) and then falling back to package defaults.

## Usage

``` r
.get_beacon_defaults(beacon_name)
```

## See also

[`.get_beacon_json()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-get_beacon_json.md)
