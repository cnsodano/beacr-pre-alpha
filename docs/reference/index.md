# Package index

## Core Functions

- [`get_seed()`](https://github.com/cnsodano/beacr-pre-alpha/reference/get_seed.md)
  : Get a new fresh seed from the latest pulse sent by a Beacon of
  choice.
- [`reset_seed_log()`](https://github.com/cnsodano/beacr-pre-alpha/reference/reset_seed_log.md)
  : Remove stale seed logs to allow acquiring and logging a new random
  value

## Public Utilities

Utilities that may be useful for everyday use of the package, not only
for developers

- [`read_logs()`](https://github.com/cnsodano/beacr-pre-alpha/reference/read_logs.md)
  : Read the debug log
- [`verify_log()`](https://github.com/cnsodano/beacr-pre-alpha/reference/verify_log.md)
  : Verify the contents of a seed log are internally consistent

## Beacons

Currently available Beacon implementations

- [`BeaconInterface`](https://github.com/cnsodano/beacr-pre-alpha/reference/BeaconInterface.md)
  :

  Public interface for implementing a new `beacr`-compatible Beacon
  object from a R6 class.

- [`NISTBeacon`](https://github.com/cnsodano/beacr-pre-alpha/reference/NISTBeacon.md)
  : NIST Interoperable Randomness Beacon Interface

## Internal

Internal functions for developers

- [`.onLoad()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-onLoad.md)
  : Hook to run when loading the package.

- [`.reset_data_dir()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-reset_data_dir.md)
  : Delete the data directory where seed log and debug log files are
  stored by default

- [`.any_is_null()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-any_is_null.md)
  : Check if there are any nulls in a list of objects

- [`.as_bits()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-as_bits.md)
  : Helper for visualizing the raw bit form of a byte vector

- [`.change_byte()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-change_byte.md)
  : Change the leading byte of a hash digest by one bit

- [`.cli_progress_output()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-cli_progress_output.md)
  : Write a temporary msg to stdout that will be removed upon
  progressbar completion

- [`.concatenate_hashes()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-concatenate_hashes.md)
  : Convert and concatenate two values into a single raw bytes objec

- [`.delete_json()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-delete_json.md)
  : Delete a file if it is a JSON file type

- [`.delete_json_in_dir()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-delete_json_in_dir.md)
  : Delete every JSON file in a directory

- [`.dt_to_ms()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-dt_to_ms.md)
  : Convert from a lubridate-style datetime to a NIST 'milliseconds
  since epoch' representation

- [`.get_beacon_defaults()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-get_beacon_defaults.md)
  : Get the options that need to be set for a specific Beacon to work

- [`.get_beacon_json()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-get_beacon_json.md)
  : Read the JSON file specifying default settings values for a specific
  Beacon

- [`.get_option()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-get_option.md)
  :

  Get the value of a `beacr`-specific global option

- [`.hex_str_to_raw()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-hex_str_to_raw.md)
  : Convert from a hexadecimal character string to a sequence of raw hex
  bytes

- [`.is_integer_like()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-is_integer_like.md)
  : Check if a value can be represented as an integer without loss

- [`.ms_to_dt()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-ms_to_dt.md)
  : Convert from NIST 'milliseconds-since-epoch' to a workable datetime
  via lubridate

- [`.posix_to_NIST_UNIX()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-posix_to_NIST_UNIX.md)
  :

  Convert from R's POSIXct data type to the time encoding used by the
  NISTBeacon, namely **milliseconds** since epoch

- [`.preregistration_exists()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-preregistration_exists.md)
  : Verify if any preregistration information was provided Currently
  used in get_seed and verify_log

- [`.printt()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-printt.md)
  : Print out NIST UNIX timestamps (milliseconds since epoch) in a
  readable way

- [`.prompt_menu()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-prompt_menu.md)
  :

  Thin wrapper around `menu` to allow mocking in tests as mocking `menu`
  is unsupported\`

- [`.sanitize_url()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-sanitize_url.md)
  : Sanitize preregistration identifier strings and parse for OSF file
  IDs

- [`.seed_log_exists()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-seed_log_exists.md)
  : Check for seed log in directory

- [`.setup_logging()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-setup_logging.md)
  : Set up logger for the package

- [`.set_option()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-set_option.md)
  :

  Set the value of a `beacr`-specific global option

- [`.timeStamp_to_unix_time()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-timeStamp_to_unix_time.md)
  : Converts a string return value from an API that represents a
  timestamp into a timestamp integer in the format expected by the
  NISTBeacon; namely, milliseconds since epoch

- [`.to_raw()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-to_raw.md)
  : Dispatcher for conversion to atomic raw byte vector type

## All internal & external names alphabetically

- [`BeaconInterface`](https://github.com/cnsodano/beacr-pre-alpha/reference/BeaconInterface.md)
  :

  Public interface for implementing a new `beacr`-compatible Beacon
  object from a R6 class.

- [`.any_is_null()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-any_is_null.md)
  : Check if there are any nulls in a list of objects

- [`.as_bits()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-as_bits.md)
  : Helper for visualizing the raw bit form of a byte vector

- [`.change_byte()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-change_byte.md)
  : Change the leading byte of a hash digest by one bit

- [`.cli_progress_output()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-cli_progress_output.md)
  : Write a temporary msg to stdout that will be removed upon
  progressbar completion

- [`.concatenate_hashes()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-concatenate_hashes.md)
  : Convert and concatenate two values into a single raw bytes objec

- [`.delete_json()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-delete_json.md)
  : Delete a file if it is a JSON file type

- [`.delete_json_in_dir()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-delete_json_in_dir.md)
  : Delete every JSON file in a directory

- [`.dt_to_ms()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-dt_to_ms.md)
  : Convert from a lubridate-style datetime to a NIST 'milliseconds
  since epoch' representation

- [`.get_beacon_defaults()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-get_beacon_defaults.md)
  : Get the options that need to be set for a specific Beacon to work

- [`.get_beacon_json()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-get_beacon_json.md)
  : Read the JSON file specifying default settings values for a specific
  Beacon

- [`.get_option()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-get_option.md)
  :

  Get the value of a `beacr`-specific global option

- [`.hex_str_to_raw()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-hex_str_to_raw.md)
  : Convert from a hexadecimal character string to a sequence of raw hex
  bytes

- [`.is_integer_like()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-is_integer_like.md)
  : Check if a value can be represented as an integer without loss

- [`.ms_to_dt()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-ms_to_dt.md)
  : Convert from NIST 'milliseconds-since-epoch' to a workable datetime
  via lubridate

- [`.posix_to_NIST_UNIX()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-posix_to_NIST_UNIX.md)
  :

  Convert from R's POSIXct data type to the time encoding used by the
  NISTBeacon, namely **milliseconds** since epoch

- [`.preregistration_exists()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-preregistration_exists.md)
  : Verify if any preregistration information was provided Currently
  used in get_seed and verify_log

- [`.printt()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-printt.md)
  : Print out NIST UNIX timestamps (milliseconds since epoch) in a
  readable way

- [`.prompt_menu()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-prompt_menu.md)
  :

  Thin wrapper around `menu` to allow mocking in tests as mocking `menu`
  is unsupported\`

- [`.sanitize_url()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-sanitize_url.md)
  : Sanitize preregistration identifier strings and parse for OSF file
  IDs

- [`.seed_log_exists()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-seed_log_exists.md)
  : Check for seed log in directory

- [`.setup_logging()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-setup_logging.md)
  : Set up logger for the package

- [`.set_option()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-set_option.md)
  :

  Set the value of a `beacr`-specific global option

- [`.timeStamp_to_unix_time()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-timeStamp_to_unix_time.md)
  : Converts a string return value from an API that represents a
  timestamp into a timestamp integer in the format expected by the
  NISTBeacon; namely, milliseconds since epoch

- [`.to_raw()`](https://github.com/cnsodano/beacr-pre-alpha/reference/dot-to_raw.md)
  : Dispatcher for conversion to atomic raw byte vector type

- [`get_seed()`](https://github.com/cnsodano/beacr-pre-alpha/reference/get_seed.md)
  : Get a new fresh seed from the latest pulse sent by a Beacon of
  choice.

- [`NISTBeacon`](https://github.com/cnsodano/beacr-pre-alpha/reference/NISTBeacon.md)
  : NIST Interoperable Randomness Beacon Interface

- [`read_logs()`](https://github.com/cnsodano/beacr-pre-alpha/reference/read_logs.md)
  : Read the debug log

- [`reset_seed_log()`](https://github.com/cnsodano/beacr-pre-alpha/reference/reset_seed_log.md)
  : Remove stale seed logs to allow acquiring and logging a new random
  value

- [`swirl()`](https://github.com/cnsodano/beacr-pre-alpha/reference/swirl.md)
  : Mix together the output of multiple randomness beacons to produce a
  random number robust to protocol deviations from any one beacon

- [`verify_log()`](https://github.com/cnsodano/beacr-pre-alpha/reference/verify_log.md)
  : Verify the contents of a seed log are internally consistent

- [`where_is_seed_log()`](https://github.com/cnsodano/beacr-pre-alpha/reference/where_is_seed_log.md)
  :

  Find where the information needed to verify the seeds acquired by
  `get_seed` is being written to by default
