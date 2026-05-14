# NIST Interoperable Randomness Beacon Interface

An R6 class providing a high-level interface to the NIST Interoperable
Randomness Beacon API. Inherits from `BeaconInterface`, which handles
initialization, configuration loading, and (In the future \#\_RETURN:)
shared utilities such as `to_raw()` and `is_valid_hash()`.

The NIST Beacon publishes signed, timestamped random values ("pulses")
at regular intervals. Each pulse is chained to its predecessor via hash
and pre-commitment values, allowing consumers to verify that no pulse
has been tampered with after the fact.

## Errors

- Propagates any error raised by `validate_pulse()` if the fetched pulse
  fails integrity checks.

- Propagates HTTP errors from `httr2` if the API request fails.

&nbsp;

- Raises an `httr2` error if the HTTP request fails (e.g. network
  unavailable, non-2xx response).

&nbsp;

- Raises an `httr2` error if the HTTP request fails, including when the
  requested chain/pulse combination does not exist (HTTP 404).

&nbsp;

- Raises an `httr2` error if the HTTP request fails, including when no
  pulse exists for the given timestamp (e.g. a time before the beacon
  was active).

&nbsp;

- Raises an error with message `"Error; pulse could not be validated"`
  if either the previous-value check or the pre-commitment check fails.
  Possible root causes include:

  - API inconsistency causing a mismatched prior pulse.

  - Evidence of beacon tampering or non-malicious drift from protocol

  - A schema change in the NIST Beacon API that alters field names or
    structure.

  - A gap in the pulse sequence (missing pulses in the chain).

- Propagates `httr2` errors if the request for the prior pulse fails.

## Warnings

- Issues a warning (via `validate_pulse()`) when the fetched pulse has
  `pulseIndex == 1` and chain-linkage validation is therefore skipped.

&nbsp;

- Issues a warning when `pulse$pulseIndex == 1`, because there is no
  prior pulse to validate against. In this case validation is skipped
  and `TRUE` is returned unconditionally.

&nbsp;

- If `value` is not a `raw` object, a warning of the form
  `"Object '<value>' is not a raw byte object. Attempting to automatically convert..."`
  is issued before coercion is attempted. If `to_raw()` cannot convert
  the object it will raise its own error.

## Super class

[`BeaconInterface`](https://github.com/cnsodano/beacr-pre-alpha/reference/BeaconInterface.md)
-\> `NISTBeacon`

## Public fields

- `hash_function`:

  A function object resolved at initialization by
  `BeaconInterface$resolve_hash_function()`. Performs the hashing
  algorithm declared in the beacon's JSON configuration file (e.g.
  SHA-512).

- `hash_length_bits`:

  Integer. The bit-length of the hash digest used by this beacon (e.g.
  `512`).

- `hash_length_bytes`:

  Integer. The byte-length of the hash digest, equal to
  `hash_length_bits / 8`.

## Active bindings

- `hash_length_bytes`:

  Integer. The byte-length of the hash digest, equal to
  `hash_length_bits / 8`.

## Methods

### Public methods

- [`NISTBeacon$new()`](#method-NISTBeacon-initialize)

- [`NISTBeacon$get_latest_seed()`](#method-NISTBeacon-get_latest_seed)

- [`NISTBeacon$get_latest_pulse()`](#method-NISTBeacon-get_latest_pulse)

- [`NISTBeacon$get_pulse_index()`](#method-NISTBeacon-get_pulse_index)

- [`NISTBeacon$get_pulse_time()`](#method-NISTBeacon-get_pulse_time)

- [`NISTBeacon$get_pulse_generic()`](#method-NISTBeacon-get_pulse_generic)

- [`NISTBeacon$validate_pulse()`](#method-NISTBeacon-validate_pulse)

- [`NISTBeacon$hash()`](#method-NISTBeacon-hash)

- [`NISTBeacon$verify_historical_seed()`](#method-NISTBeacon-verify_historical_seed)

- [`NISTBeacon$get_timestamp_from_pulse()`](#method-NISTBeacon-get_timestamp_from_pulse)

- [`NISTBeacon$skip_list_verification()`](#method-NISTBeacon-skip_list_verification)

- [`NISTBeacon$found_pulse()`](#method-NISTBeacon-found_pulse)

- [`NISTBeacon$calculate_time_delta()`](#method-NISTBeacon-calculate_time_delta)

- [`NISTBeacon$get_previous_pulse()`](#method-NISTBeacon-get_previous_pulse)

- [`NISTBeacon$check_pulse_can_be_identified()`](#method-NISTBeacon-check_pulse_can_be_identified)

- [`NISTBeacon$get_prev_value_from_pulse()`](#method-NISTBeacon-get_prev_value_from_pulse)

- [`NISTBeacon$convert_to_unix_milliseconds()`](#method-NISTBeacon-convert_to_unix_milliseconds)

- [`NISTBeacon$to_raw()`](#method-NISTBeacon-to_raw)

- [`NISTBeacon$clone()`](#method-NISTBeacon-clone)

Inherited methods

- [`BeaconInterface$get_description()`](https://github.com/cnsodano/beacr-pre-alpha/reference/BeaconInterface.html#method-get_description)
- [`BeaconInterface$get_pulse_by_index()`](https://github.com/cnsodano/beacr-pre-alpha/reference/BeaconInterface.html#method-get_pulse_by_index)
- [`BeaconInterface$is_valid_hash()`](https://github.com/cnsodano/beacr-pre-alpha/reference/BeaconInterface.html#method-is_valid_hash)
- [`BeaconInterface$replay_file_exists()`](https://github.com/cnsodano/beacr-pre-alpha/reference/BeaconInterface.html#method-replay_file_exists)
- [`BeaconInterface$resolve_hash_function()`](https://github.com/cnsodano/beacr-pre-alpha/reference/BeaconInterface.html#method-resolve_hash_function)

------------------------------------------------------------------------

### `NISTBeacon$new()`

#### Usage

    NISTBeacon$new(...)

------------------------------------------------------------------------

### `NISTBeacon$get_latest_seed()`

Fetch, validate, and return the most recent pulse's output as an integer
seed.

Combines `get_latest_pulse()` and `validate_pulse()` into a single
convenience call. The raw `outputValue` field of the pulse is converted
to an integer vector via `to_raw()` before being returned.

#### Usage

    NISTBeacon$get_latest_seed(chain = "last")

#### Arguments

- `chain`:

  `character(1)` or `numeric(1)`. The chain to query. Accepts either a
  numeric chain index or the special string `"last"` (default), which
  resolves to the most recently active chain.

#### Returns

An integer vector derived from the pulse's `outputValue` field. The
length of the vector corresponds to `hash_length_bytes`.

#### Examples

    beacon <- NISTBeacon$new()

    # Latest seed from the most recent chain
    seed <- beacon$get_latest_seed()

    # Latest seed from a specific chain
    seed <- beacon$get_latest_seed(chain = 1)

------------------------------------------------------------------------

### `NISTBeacon$get_latest_pulse()`

Fetch the most recent pulse from a given chain.

Makes a `GET` request to `<api_base_url>/chain/<chain>/pulse/last` and
returns the parsed pulse object. No validation is performed; call
`validate_pulse()` on the result if integrity checking is required.

#### Usage

    NISTBeacon$get_latest_pulse(chain = "last")

#### Arguments

- `chain`:

  `character(1)` or `numeric(1)`. The chain to query. Accepts either a
  numeric chain index or the special string `"last"` (default), which
  resolves to the most recently active chain.

#### Returns

A named `list` representing the pulse object as returned by the NIST
Beacon API. Key fields include:

- `$outputValue` — the hex-encoded random output for this pulse.

- `$chainIndex` — the index of the chain this pulse belongs to.

- `$pulseIndex` — the position of this pulse within its chain.

- `$precommitmentValue` — a hash commitment to the *next* pulse's local
  random value, used for forward-validation.

- `$listValues` — a data frame of previous pulses' `outputValue`
  includes the columns "uri" (to make the HTTP request to retrieve that
  pulse), "type" (e.g. `previous`, `year`, `month`, `day` or `hour`.
  NIST v2.0 has a pulse period of 60 seconds, so `previous` is the same
  as '1 minute ago')

#### Examples

    beacon <- NISTBeacon$new()

    # Fetch from the most recent chain
    pulse <- beacon$get_latest_pulse()
    pulse$outputValue

    # Fetch from a specific chain
    pulse <- beacon$get_latest_pulse(chain = 1)

------------------------------------------------------------------------

### `NISTBeacon$get_pulse_index()`

Fetch a specific pulse by chain index and pulse index.

Unlike `get_latest_pulse()`, this method requires both arguments
explicitly — there are no defaults. Use this when you need a
reproducible reference to a particular pulse (e.g. for auditing or
seeding a simulation with a historically fixed value).

#### Usage

    NISTBeacon$get_pulse_index(chain_index, pulse_index)

#### Arguments

- `chain_index`:

  `numeric(1)`. The index of the chain containing the desired pulse.

- `pulse_index`:

  `numeric(1)`. The index of the pulse within the specified chain.

#### Returns

A named `list` representing the pulse object. See `get_latest_pulse()`
for a description of key fields.

#### Examples

    beacon <- NISTBeacon$new()

    # Fetch the 42nd pulse from chain 1
    pulse <- beacon$get_pulse_index(chain_index = 1, pulse_index = 42)
    pulse$outputValue

------------------------------------------------------------------------

### `NISTBeacon$get_pulse_time()`

Fetch the pulse that was current at a given Unix timestamp.

Queries the NIST Beacon's time-based endpoint to retrieve whichever
pulse was active at the specified moment. This is useful for
reproducibly seeding a process from a wall-clock time. \#\_RETURN
correct data type and mention str concat

#### Usage

    NISTBeacon$get_pulse_time(unix_time)

#### Arguments

- `unix_time`:

  `numeric(1)`. A Unix timestamp (integer seconds since 1970-01-01
  00:00:00 UTC) identifying the point in time for which the
  corresponding pulse should be retrieved.

  Note: human-readable date/time strings are not currently accepted.
  Convert them first with, for example, \#\_RETURN correct this ex and
  mention str concat
  `as.numeric(as.POSIXct("2024-01-01 12:00:00", tz = "UTC"))`.

#### Returns

A named `list` representing the pulse object active at `unix_time`. See
`get_latest_pulse()` for a description of key fields.

#### Examples

    beacon <- NISTBeacon$new()

    # Fetch the pulse active at a specific moment
    #_RETURN issue here re: numeric, etc
    t <- as.numeric(as.POSIXct("2024-06-01 00:00:00", tz = "UTC"))
    pulse <- beacon$get_pulse_time(unix_time = t)
    pulse$outputValue

------------------------------------------------------------------------

### `NISTBeacon$get_pulse_generic()`

#### Usage

    NISTBeacon$get_pulse_generic(
      chain_index = NULL,
      pulse_index = NULL,
      timestamp = NULL
    )

------------------------------------------------------------------------

### `NISTBeacon$validate_pulse()`

Validate the integrity of a pulse by checking its chain linkage.

Performs two checks against the pulse immediately preceding the one
supplied:

1.  **Previous-value check** — confirms that the `"previous"` entry in
    the current pulse's `listValues` matches the `outputValue` of the
    actual prior pulse fetched from the API.

2.  **Pre-commitment check** — confirms that hashing the current pulse's
    `localRandomValue` reproduces the `precommitmentValue` that was
    published in the prior pulse. This is essential to proving there has
    been no tampering in between pulses

#### Usage

    NISTBeacon$validate_pulse(pulse)

#### Arguments

- `pulse`:

  A named `list` as returned by `get_latest_pulse()`,
  `get_pulse_index()`, or `get_pulse_time()`. Must contain at minimum
  the fields `$chainIndex`, `$pulseIndex`, `$outputValue`,
  `$localRandomValue`, and `$listValues`.

#### Returns

`TRUE` (invisibly) if both checks pass, or if `pulseIndex == 1` (see
Warnings). Never returns `FALSE`; failure always raises an error.

#### Examples

    beacon <- NISTBeacon$new()
    pulse <- beacon$get_latest_pulse()

    # Validate a pulse before using its output
    beacon$validate_pulse(pulse)

    # Validate a historical pulse
    old_pulse <- beacon$get_pulse_index(chain_index = 1, pulse_index = 100)
    beacon$validate_pulse(old_pulse)

------------------------------------------------------------------------

### `NISTBeacon$hash()`

Hash a value using the beacon's configured hash function.

The underlying algorithm (e.g. SHA-512) is determined at initialization
by `BeaconInterface$resolve_hash_function()` reading the beacon's JSON
configuration file, and is stored in `self$hash_function`. If `value` is
not already a raw byte vector it will be coerced via `to_raw()` using
`self$hash_length_bits` as the target width, and a warning will be
issued.

#### Usage

    NISTBeacon$hash(value)

#### Arguments

- `value`:

  The object to hash. Ideally a `raw` byte vector. Any other type will
  trigger an automatic conversion attempt via `to_raw()` (see Warnings).

#### Returns

A `raw` vector containing the hash digest of `value`, with length equal
to `self$hash_length_bytes`.

#### Examples

    beacon <- NISTBeacon$new()

    # Hash a raw vector directly (no warning)
    raw_val <- as.raw(c(0x01, 0x02, 0x03))
    digest  <- beacon$hash(raw_val)

    # Hash a string — triggers automatic coercion warning
    digest <- beacon$hash("2F1A9B99A")
    Documentation: meniton the major headache with clamping and subpulse precision and etc; moved away from using timestamps and just pulse idxs
     Used to clamp the start_time to
    last known timestamp to avoid
    any issues w/ sub-pulse-period
    precision
     #! _RETURN Warn about automatically checking from curr time;
     #! _RETURN if inputting start_time warn about milliseconds, etc
    Estimate the max number of API calls one would need to verify using a skiplist that a historical pulse being verified is on the same chain as another pulse

------------------------------------------------------------------------

### `NISTBeacon$verify_historical_seed()`

#### Usage

    NISTBeacon$verify_historical_seed(
      chain_index = NULL,
      pulse_index = NULL,
      timestamp = NULL,
      pulse_to_check = NULL,
      start_pulse = NULL
    )

------------------------------------------------------------------------

### `NISTBeacon$get_timestamp_from_pulse()`

#### Usage

    NISTBeacon$get_timestamp_from_pulse(pulse, as_unix = FALSE)

------------------------------------------------------------------------

### `NISTBeacon$skip_list_verification()`

#### Usage

    NISTBeacon$skip_list_verification(pulse_to_check, start_pulse = NULL)

------------------------------------------------------------------------

### `NISTBeacon$found_pulse()`

#### Usage

    NISTBeacon$found_pulse(curr_pulse, pulse_to_check)

------------------------------------------------------------------------

### `NISTBeacon$calculate_time_delta()`

#### Usage

    NISTBeacon$calculate_time_delta(
      pulse,
      start_time = NULL,
      direction = "backwards"
    )

------------------------------------------------------------------------

### `NISTBeacon$get_previous_pulse()`

#### Usage

    NISTBeacon$get_previous_pulse(pulse)

------------------------------------------------------------------------

### `NISTBeacon$check_pulse_can_be_identified()`

#### Usage

    NISTBeacon$check_pulse_can_be_identified(pulse_index, chain_index, timestamp)

------------------------------------------------------------------------

### `NISTBeacon$get_prev_value_from_pulse()`

#### Usage

    NISTBeacon$get_prev_value_from_pulse(pulse, type_ = "previous")

------------------------------------------------------------------------

### `NISTBeacon$convert_to_unix_milliseconds()`

#### Usage

    NISTBeacon$convert_to_unix_milliseconds(
      time = Sys.time(),
      offset = FALSE,
      offset_amount = 61
    )

------------------------------------------------------------------------

### `NISTBeacon$to_raw()`

#### Usage

    NISTBeacon$to_raw(value, bits = self$hash_length_bits)

------------------------------------------------------------------------

### `NISTBeacon$clone()`

The objects of this class are cloneable with this method.

#### Usage

    NISTBeacon$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples
