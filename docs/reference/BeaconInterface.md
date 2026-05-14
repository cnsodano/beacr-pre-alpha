# Public interface for implementing a new `beacr`-compatible Beacon object from a R6 class.

Public interface for implementing a new `beacr`-compatible Beacon object
from a R6 class.

## Methods

### Public methods

- [`BeaconInterface$new()`](#method-BeaconInterface-initialize)

- [`BeaconInterface$replay_file_exists()`](#method-BeaconInterface-replay_file_exists)

- [`BeaconInterface$resolve_hash_function()`](#method-BeaconInterface-resolve_hash_function)

- [`BeaconInterface$is_valid_hash()`](#method-BeaconInterface-is_valid_hash)

- [`BeaconInterface$get_pulse_by_index()`](#method-BeaconInterface-get_pulse_by_index)

- [`BeaconInterface$get_description()`](#method-BeaconInterface-get_description)

- [`BeaconInterface$get_latest_seed()`](#method-BeaconInterface-get_latest_seed)

- [`BeaconInterface$get_latest_pulse()`](#method-BeaconInterface-get_latest_pulse)

- [`BeaconInterface$get_pulse_index()`](#method-BeaconInterface-get_pulse_index)

- [`BeaconInterface$get_pulse_time()`](#method-BeaconInterface-get_pulse_time)

- [`BeaconInterface$validate_pulse()`](#method-BeaconInterface-validate_pulse)

- [`BeaconInterface$hash()`](#method-BeaconInterface-hash)

- [`BeaconInterface$clone()`](#method-BeaconInterface-clone)

------------------------------------------------------------------------

### `BeaconInterface$new()`

#### Usage

    BeaconInterface$new(...)

------------------------------------------------------------------------

### `BeaconInterface$replay_file_exists()`

#### Usage

    BeaconInterface$replay_file_exists()

------------------------------------------------------------------------

### `BeaconInterface$resolve_hash_function()`

#### Usage

    BeaconInterface$resolve_hash_function()

------------------------------------------------------------------------

### `BeaconInterface$is_valid_hash()`

#### Usage

    BeaconInterface$is_valid_hash(hashed_value, comparison_value = NULL)

------------------------------------------------------------------------

### `BeaconInterface$get_pulse_by_index()`

#### Usage

    BeaconInterface$get_pulse_by_index(...)

------------------------------------------------------------------------

### `BeaconInterface$get_description()`

#### Usage

    BeaconInterface$get_description()

------------------------------------------------------------------------

### `BeaconInterface$get_latest_seed()`

#### Usage

    BeaconInterface$get_latest_seed(...)

------------------------------------------------------------------------

### `BeaconInterface$get_latest_pulse()`

#### Usage

    BeaconInterface$get_latest_pulse(...)

------------------------------------------------------------------------

### `BeaconInterface$get_pulse_index()`

#### Usage

    BeaconInterface$get_pulse_index(...)

------------------------------------------------------------------------

### `BeaconInterface$get_pulse_time()`

#### Usage

    BeaconInterface$get_pulse_time(...)

------------------------------------------------------------------------

### `BeaconInterface$validate_pulse()`

#### Usage

    BeaconInterface$validate_pulse(...)

------------------------------------------------------------------------

### `BeaconInterface$hash()`

#### Usage

    BeaconInterface$hash(...)

------------------------------------------------------------------------

### `BeaconInterface$clone()`

The objects of this class are cloneable with this method.

#### Usage

    BeaconInterface$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
