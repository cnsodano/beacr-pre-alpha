# Public interface for implementing a new `beacr`-compatible Beacon object from a R6 class.

Public interface for implementing a new `beacr`-compatible Beacon object
from a R6 class.

## See also

[`.get_beacon_defaults()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-get_beacon_defaults.md)

## Methods

### Public methods

- [`BeaconInterface$new()`](#method-BeaconInterface-initialize)

- [`BeaconInterface$resolve_hash_function()`](#method-BeaconInterface-resolve_hash_function)

- [`BeaconInterface$hash()`](#method-BeaconInterface-hash)

- [`BeaconInterface$to_raw()`](#method-BeaconInterface-to_raw)

- [`BeaconInterface$get_pulse()`](#method-BeaconInterface-get_pulse)

- [`BeaconInterface$is_valid_hash()`](#method-BeaconInterface-is_valid_hash)

- [`BeaconInterface$verify_historical_seed()`](#method-BeaconInterface-verify_historical_seed)

- [`BeaconInterface$clone()`](#method-BeaconInterface-clone)

------------------------------------------------------------------------

### `BeaconInterface$new()`

Constructor method for new beacons. Defers settings of fields to default
values found in the `beacons.json` spec file at
`inst/extdata/beacons.json`. Each Beacon implementation should call
`super$initialize(...)` to benefit from this logic. Any

#### Usage

    BeaconInterface$new(...)

#### Details

For each setting argument passed to the constructor, prioriy goes to the
user-passed value, then to the globally set option if there is any, then
to the package's default

In theory this allows initializing\>1 Beacon objects with differing
settings for testing or combining beacons

------------------------------------------------------------------------

### `BeaconInterface$resolve_hash_function()`

A resolver for selecting the library provider for the hash functions
needed by a Beacon. This allows for less dependency on any specific hash
library. To change libraries, update the 'current_hash_library' and
'hash_libraries' keys in `inst/extdata/package_settings.json`

#### Usage

    BeaconInterface$resolve_hash_function()

------------------------------------------------------------------------

### `BeaconInterface$hash()`

Hash a value according to the specifics (hash digest bit length, hash
function, etc) of the particular beacon

#### Usage

    BeaconInterface$hash(...)

------------------------------------------------------------------------

### `BeaconInterface$to_raw()`

Convert a beacon value to a raw byte vector, mainly used to convert hex
strings from Beacon APIs into R raw byte atomic vector types

#### Usage

    BeaconInterface$to_raw(value, bits = self$hash_length_bits)

------------------------------------------------------------------------

### `BeaconInterface$get_pulse()`

Get a pulse from the Beacon.

#### Usage

    BeaconInterface$get_pulse(
      chain_index = NULL,
      pulse_index = NULL,
      timestamp = NULL
    )

------------------------------------------------------------------------

### `BeaconInterface$is_valid_hash()`

Verify that a hashed value is consistent with the specification for a
Beacon, namely the bit length. Optionally, compare between two hash
values to check for equality. Useful for Beacon-specific internal
validity checks, e.g. checking that the hash of a NISTBeacon's pulse
randLocal value matches the previous pulse's precommitmentValue

#### Usage

    BeaconInterface$is_valid_hash(hashed_value, comparison_value = NULL)

------------------------------------------------------------------------

### `BeaconInterface$verify_historical_seed()`

Verify that a previous seed logged is consistent on the pulse chain
\#!\_RETURN Change to more specific name

#### Usage

    BeaconInterface$verify_historical_seed(...)

------------------------------------------------------------------------

### `BeaconInterface$clone()`

The objects of this class are cloneable with this method.

#### Usage

    BeaconInterface$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
