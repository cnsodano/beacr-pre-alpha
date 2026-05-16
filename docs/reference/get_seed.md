# Get a new fresh seed from the latest pulse sent by a Beacon of choice.

Get a new fresh seed from the latest pulse sent by a Beacon of choice.

## Usage

``` r
get_seed(
  log_file = NULL,
  preregistration_identifier = NULL,
  preregistration_source = c("OSF"),
  Beacon = NISTBeacon,
  pulse_index = NULL,
  chain_index = NULL,
  timestamp = NULL,
  starting_pulse_for_verification = NULL
)
```

## Arguments

- log_file:

  A path to the file that the seed log will be saved at. Defaults to
  /beacr/seed_log.json

- preregistration_identifier:

  A string representing the unique resource identifier (URI) of an
  external resource that specifies a protocol or outcome that you have
  pre-committed to prior to requesting a seed. Combined with
  preregistration_source, this identifier allows verifying that the
  preregistration was published prior to the pulse being requested and
  ensures that later reproductions of analyses using this function for
  seeding are innately tied to the precommiteed protocol (via
  hash-concatenation). Currently only supports OSF API v2 file URIs.

- preregistration_source:

  A string representing the provider of the external preregistration
  resource to be used for verifying precommitted claims/protocols.
  Currently only supports the Open Science Framework ("OSF").

- Beacon:

  An R6 object implementing the `BeaconInterface` which provides all
  logic for requesting a fresh randomness pulse from a specific Beacon.
  Currently only supports `NISTBeacon` and is not intended to be passed
  by default, but experienced users can implement their own `Beacon`
  classes to extend support for a Beacon of choice.

- pulse_index:

  The index of a pulse if you wish to get a seed from a particular
  pulse, instead of the most recent. Must be passed with chain_index. If
  integer/numeric, will be coerced to string during API call
  construction. If "last", will pull the most recent pulse on the chain

- chain_index:

  The chain of a pulse if you wish to get a seed from a particular
  pulse, instead of the most recent. Must be passed with pulse_index. If
  integer/numeric, will be coerced to string during API call
  construction. If "last", will pull the most recently started chain

- timestamp:

  double/char representing the UNIX time (milliseconds since epoch of
  00:00:00 UTC on Thursday, 1 January 1970) of a pulse if you wish to
  get a seed from a particular pulse, instead of the most recent. Note:
  beware of using an integer type when working with timestamps as the
  base R maximum integer limit of ((2^31)-1) is too small to represent
  most dates measured in milliseconds without converting the timestamp
  to NA due to overflow

- starting_pulse_for_verification:

  See
  [verify_log](https://github.com/cnsodano/beacr-pre-alpha/reference/verify_log.md)
  for details

## Value

A vector of raw bytes representing a random bitstream from a beacon \#'
pulse

## Details

By default a JSON log file will be created that records the following
information about the seed request:

- The timestamp the pulse was requested,

- The Beacon the pulse was requested from and details about the HTTP
  request made \#!\_RETURN implement

- The pulse information adapted from the JSON API response of the Beacon

- Optionally (and highly encouraged), information about a
  preregistration made prior to requesting a seed. More information
  about preregistrations can be found at the `Preregistration` section
  of the Getting Started vignette \#!\_RETURN link

By default this log will be saved to the directory specified by the
package option "beacr.data_dir_location" which defaults to
`<WORKSPACE>/beacr/` but a log file path can be passed directly. Call
\`beacr::where_is_seed_log()“ to find where this file is stored.

This file will be then be used on the next call to `get_seed(...)` to
'replay' the recorded pulse request and verify that the contents of the
log are internally consistent (using `verify_log(...)`. If an identifier
for an external preregistration source is passed via
preregistration_identifier and preregistration_source, this resource
will be downloaded and validated as part of the verification process. If
using this function call as a source of a verifiably random,
reproducible seed, you should pass a local path (i.e. relative to the
workspace that the code using the seed will be found in and shared) so
that this log is available to others trying to reproduce the pulse.

The default Beacon can be found in the package directory under
`/inst/extdata/package_settings.json` and the details of all currently
supported beacons can be found at `/inst/extdata/package_settings.json`.
For advanced use, users can pass a custom Beacon object which is an
instance of and R6 class that implements the `R/BeaconInterface.R`
interface.

## See also

[verify_log](https://github.com/cnsodano/beacr-pre-alpha/reference/verify_log.md)

## Examples
