# beacr

## Installing `beacr`

Currently, `beacr` is not yet available on CRAN. Install `beacr`
directly from GitHub using `pak`(recommended), `remotes`, or
`devtools`(deprecated) \#### pak

``` r

# install.packages("pak")
pak::pak("cnsodano/beacr-pre-alpha")
```

#### remotes

``` r

# install.packages("remotes")
remotes::install_github("cnsodano/beacr-pre-alpha")
```

#### devtools

``` r

# install.packages("devtools")
devtools::install_github('cnsodano/beacr-pre-alpha')
```

## Using `beacr`

The most simple use case for `beacr` is when you want to set your random
number generator seed to a number that is both completely random and
reproducible. That code may look something like this:

``` r

seed = beacr::get_seed()
set.seed(seed)
# Continue with reproducible random processes...
```

When
[`get_seed()`](https://github.com/cnsodano/beacr-pre-alpha/reference/get_seed.md)
is called, a seed log is written that captures the details of the seed
that was returned based on the beacon(s) used.

``` r

# Acquire seed
seed = beacr::get_seed()
#> ℹ Did not detect a seed log file. Writing one to
#>   `C:/Users/cnsodano/AppData/Local/Temp/Rtmpgx6ahL/PROJ_ROOT/beacr/seed_log.json`
#> ✖ No preregistration identifier passed, using pulse without preregistration.
#>   See the 'Preregistration' section in the Getting Started vignette for more
#>   details: `vignette('beacr')`
#> ✔ Pulse successfully acquired. Details written to log at C:/Users/cnsodano/AppData/Local/Temp/Rtmpgx6ahL/PROJ_ROOT/beacr/seed_log.json
```

After acquiring a random seed, you can use it for reproducible analyses
like so:

``` r

# Set seed acquired
set.seed(seed)

# Use reproducible seed
random_draws <- rnorm(10)
random_draws
#>  [1] -0.08248519 -0.43543157 -0.68188329 -1.89945831  0.58261495  1.07733680
#>  [7] -0.71613263 -0.32682606 -0.57023004  0.58244249
```

Then when you rerun the same code, `beacr` will read from the seed log
to reproduce the same output.

``` r

# Acquire seed (automatically reproduces previous seed acquired)
seed_reproduced = beacr::get_seed()
#> ℹ Detected seed log file at path
#>   `C:/Users/cnsodano/AppData/Local/Temp/Rtmpgx6ahL/PROJ_ROOT/beacr/seed_log.json`,
#>   reading from that file (**NOT** generating new seeds). Call
#>   `reset_seed_log()` to purge this file and generate new seeds
#> ℹ Verifying the logged pulse can be recreated...
#> ✔ The beacon pulse logged matches the beacon pulse issued at the logged timestamp
#> ℹ Verifying the chain integrity of the logged pulse...
#> ! When verifying chain integrity of logged pulse, no starting pulse was passed.
#>   Starting chain verification with the latest pulse from its chain
#> ✔ Successfully verified chain integrity of logged pulse!
#> ! Preregistration was not able to be found from the log, preventing
#>   verification of preregistration. See the 'Preregistration' section in the
#>   Getting Started vignette for more details:`vignette('beacr')`
#> ! Continuing verification assuming no preregistration made.
#> ✔ Random seed logged is consistent with the logged preregistration and logged beacon pulse value...
#> ✔ Successfully verified log! Returning reproducible seed...
```

When can then verify that the output of `get_seed` when called a second
time results in a reproducible script:

``` r

# Set reproduced seed
set.seed(seed_reproduced)
print(glue::glue("Is the reproduced seed identical to the original?: {identical(seed, seed_reproduced)}"))
#> Is the reproduced seed identical to the original?: TRUE

# Use reproducible seed
random_draws_reproduced <- rnorm(10)
random_draws_reproduced
#>  [1] -0.08248519 -0.43543157 -0.68188329 -1.89945831  0.58261495  1.07733680
#>  [7] -0.71613263 -0.32682606 -0.57023004  0.58244249
print(glue::glue("Are the random numbers drawn after seeding identical?: {identical(random_draws, random_draws_reproduced)}"))
#> Are the random numbers drawn after seeding identical?: TRUE
```

This log-based workflow makes it possible for an analysis to be
completely reproducible without requiring changing of any hard-coded
file paths or timestamp values. Note that `get_seed` does not merely
*cache* the Beacon pulse and return the cached value on the second call.
Instead, it stores all the information needed to verify and reproduce
the pulse used in a `seed_log.json` file. When called for the second
time, it re-performs the pulse acquisition and **verifies** that the
pulse returned by the Beacon is the same as that logged. Otherwise,
users could manually adjust the cached file to make it return any seed
value they desired before posting their repository.

Note on what I mean by ‘log’

The **seed log** is a JSON file holding the information needed to
reproduce the most recent seed generated from a Beacon. This is not to
be confused with the `beacr` **debug log** which is a typical `.log`
file retracing all messages, warnings, and errors that occurred during
code execution and can be viewed by calling
[`read_logs()`](https://github.com/cnsodano/beacr-pre-alpha/reference/read_logs.md)

## Pre-registration

If you wish to provide a link to an external file documenting a
preregistration of an experimental protocol or hypothesized outcome,
currently `beacr` supports using OSF API file IDs. You can pass that
like so:

``` r

# Publish a preregistration first on OSF that specifies your protocol
# and hypothesized outcomes
#
# ! Note that this file isn't a preregistration but serves as a demo !
OSF_preregistration_file_link = "https://osf.io/mbcw5/files/yahfc"

# Acquire an ex post facto verifiably reproducible seed that is
# inseparably linked to your preregistration
seed = beacr::get_seed(
  preregistration_identifier = OSF_preregistration_file_link,
  preregistration_source = "OSF"
)

# Set reproducible seed
set.seed(seed)

# Use reproducible seed
rnorm(10)
```

When passing an external preregistration, the seed generated by
`get_seed(...)` will be uniquely associated with the content of the
pre-registration file. In theory, this means that the results of the
analysis can only be reproducible if posted alongside the original
analysis plan in the form of its preregistration.¹

Technical specifics about how preregistration is incorporated into seed
generation

Specifically, the seed value returned by `get_seed` will be (by default,
using the NISTBeacon) the SHA-512 hash of the **concatenation** of

1.  The SHA-256 hash of the OSF registration **file data** (NOT the URL)
2.  The 512-bit outputValue field of the NISTBeacon JSON API response
    for the most recent pulse

As a formula,

`seed = HASH_512( HASH_256(preregistration_binary_data) || BEACON_512 )`

- *where `||` means concatenation of the binary values, not bitwise
  `OR`*
- *where BEACON_512 is the 512 bit output of the beacon*
- *where HASH_xxx is the SHA-family hash function*

Before computing this unique seed, `beacr` will verify file integrity by
downloading the pre-registration file from the OSF API URI provided, and
confirming the hash of the downloaded file matches the hash value
provided by the API (i.e. confirming there is no corruption/tampering
during transit).

#### Using a Preregistration

To use a preregistration, first ensure that you’ve cleared the seed log
that you may have already written in prior testing like so:

``` r

reset_seed_log(yes_to_all = TRUE)
#> ! Deleting all files in
#>   C:/Users/cnsodano/AppData/Local/Temp/Rtmpgx6ahL/PROJ_ROOT/beacr
```

Then continue by passing a preregistration identifier and source.
Currently, only OSF files are supported.

``` r

# Publish a preregistration first on OSF that specifies your protocol and
# hypothesized outcomes Note that this is not a preregistration but a demo file
# (actually a talk I gave at PYMS Summer Symposium 2025)
OSF_preregistration_file_link = "https://osf.io/mbcw5/files/yahfc"

# Acquire an ex post facto verifiably reproducible seed that is inseparably
# linked to your preregistration
seed = beacr::get_seed(preregistration_identifier = OSF_preregistration_file_link,
    preregistration_source = "OSF")
#> ℹ Did not detect a seed log file. Writing one to
#>   `C:/Users/cnsodano/AppData/Local/Temp/Rtmpgx6ahL/PROJ_ROOT/beacr/seed_log.json`
#> ℹ Using preregistration value with
#>   identifier:`https://osf.io/mbcw5/files/yahfc` from source: `OSF`
#> ! Validating the identifier passed to .get_preregistration_OSF() is not yet
#>   implemented; assuming the identifier to be a valid OSF URL or unique OSF file
#>   ID
#> ! Currently this package doesn't check if the file provided is from a
#>   Registration. OSF Registrations do not have writable history (i.e. they
#>   cannot be changed after publication) providing an integrity guarantee whereas
#>   normal Projects do not. Please note that public preregistrations that do not
#>   have integrity guarantees are unsuitable for this kind of commitment scheme
#>   as the whole point is to ensure that you commit to using a future value in
#>   advance specifically in a way where you cannot change your commitment after
#>   that value is known.
#> ℹ Validating OSF file hash by downloading external preregistration file...
#> ✔ Hash value reported by OSF's API matches the hash value of the actual file available for download from OSF
#> ℹ View source of preregistration value at:
#>   `https://osf.io/mbcw5/files/osfstorage/686faff93ef3be547af6d5a8`
#> ✔ Pulse successfully acquired. Details written to log at C:/Users/cnsodano/AppData/Local/Temp/Rtmpgx6ahL/PROJ_ROOT/beacr/seed_log.json
```

Once acquired, use the seed in the same way as you would without a
preregistration:

``` r

# Set reproducible seed
set.seed(seed)

# Use reproducible seed
random_draws = rnorm(10)
random_draws
#>  [1]  1.62340452  1.06150234 -0.21365654 -0.55038573  0.09891564 -0.90909823
#>  [7]  1.45784634  3.67014596 -0.86691474 -0.50402163
```

Every subsequent call to `get_seed` will reproduce the Beacon pulse with
all the validation steps mentioned above as well as verifying the
preregistration file integrity (making sure the file available on OSF
hasn’t changed since the pulse was originally acquired and logged).

``` r

# Rerunning the above code...

# Publish a preregistration first on OSF that specifies your protocol and
# hypothesized outcomes Note that this is not a preregistration but a demo file
# (actually a talk I gave at PYMS Summer Symposium 2025)
OSF_preregistration_file_link = "https://osf.io/mbcw5/files/yahfc"

# Acquire an ex post facto verifiably reproducible seed that is inseparably
# linked to your preregistration
seed_reproduced = beacr::get_seed(preregistration_identifier = OSF_preregistration_file_link,
    preregistration_source = "OSF")
#> ℹ Detected seed log file at path
#>   `C:/Users/cnsodano/AppData/Local/Temp/Rtmpgx6ahL/PROJ_ROOT/beacr/seed_log.json`,
#>   reading from that file (**NOT** generating new seeds). Call
#>   `reset_seed_log()` to purge this file and generate new seeds
#> ℹ Verifying the logged pulse can be recreated...
#> ✔ The beacon pulse logged matches the beacon pulse issued at the logged timestamp
#> ℹ Verifying the chain integrity of the logged pulse...
#> ! When verifying chain integrity of logged pulse, no starting pulse was passed.
#>   Starting chain verification with the latest pulse from its chain
#> ✔ Successfully verified chain integrity of logged pulse!
#> ℹ Detected a preregistration message in log.
#> ✔ Random seed logged is consistent with the logged preregistration and logged beacon pulse value...
#> ℹ Verifying the logged preregistration is consistent with external source...
#> ℹ Validating timestamp and hash of preregistration from external provider...
#> ! Validating the identifier passed to .get_preregistration_OSF() is not yet
#>   implemented; assuming the identifier to be a valid OSF URL or unique OSF file
#>   ID
#> ! Currently this package doesn't check if the file provided is from a
#>   Registration. OSF Registrations do not have writable history (i.e. they
#>   cannot be changed after publication) providing an integrity guarantee whereas
#>   normal Projects do not. Please note that public preregistrations that do not
#>   have integrity guarantees are unsuitable for this kind of commitment scheme
#>   as the whole point is to ensure that you commit to using a future value in
#>   advance specifically in a way where you cannot change your commitment after
#>   that value is known.
#> ℹ Validating OSF file hash by downloading external preregistration file...
#> ✔ Hash value reported by OSF's API matches the hash value of the actual file available for download from OSF
#> ✔ Preregistration was published before the logged pulse timestamp
#> ✔ Successfully verified log! Returning reproducible seed...
```

To verify that the seed reproduced in this way results in the exact same
sequence of random numbers:

``` r

# Set reproduced seed
set.seed(seed_reproduced)
print(glue::glue("Is the reproduced seed identical to the original?: {identical(seed, seed_reproduced)}"))
#> Is the reproduced seed identical to the original?: TRUE

# Use reproducible seed
random_draws_reproduced <- rnorm(10)
random_draws_reproduced
#>  [1]  1.62340452  1.06150234 -0.21365654 -0.55038573  0.09891564 -0.90909823
#>  [7]  1.45784634  3.67014596 -0.86691474 -0.50402163
print(glue::glue("Are the random numbers drawn after seeding identical?: {identical(random_draws, random_draws_reproduced)}"))
#> Are the random numbers drawn after seeding identical?: TRUE
```

  
  
  
  

#### Notes

1.  This is not technically true, as currently I use a version of the
    preregistration file that’s condensed to 32 bytes (specifically via
    the SHA-256bit hash function), so as long as that value is provided,
    the reproducible seed can be set. This is actually a crucial
    distinction for future versions of `beacr` which will allow posting
    *encrypted* preregistrations that establish primacy but don’t reveal
    what the protocol/hypothesis is until the authors are prepared to
    release the decryption key. If the authors provide the hash of the
    secret preregistration then others can reproduce the analysis even
    **before** they can read the preregistration.
