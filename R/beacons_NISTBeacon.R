#' NIST Interoperable Randomness Beacon Interface
#'
#' An R6 class providing a high-level interface to the NIST Interoperable
#' Randomness Beacon API. Inherits from `BeaconInterface`, which handles
#' initialization, configuration loading, and (In the future #_RETURN:) shared utilities such as `to_raw()` and `is_valid_hash()`.
#'
#' The NIST Beacon publishes signed, timestamped random values ("pulses") at
#' regular intervals. Each pulse is chained to its predecessor via hash and
#' pre-commitment values, allowing consumers to verify that no pulse has been
#' tampered with after the fact.
#'
#' @field hash_function A function object resolved at initialization by
#'   `BeaconInterface$resolve_hash_function()`. Performs the hashing algorithm
#'   declared in the beacon's JSON configuration file (e.g. SHA-512).
#' @field hash_length_bits Integer. The bit-length of the hash digest used by
#'   this beacon (e.g. `512`).
#' @field hash_length_bytes Integer. The byte-length of the hash digest, equal
#'   to `hash_length_bits / 8`.
#'
#' @examples
#' beacon <- NISTBeacon$new()
#' pulse  <- beacon$get_latest_pulse()
#' seed   <- beacon$get_latest_seed()
#'
#' @export
NISTBeacon <- R6::R6Class(
  classname = "NISTBeacon",
  inherit = BeaconInterface,
  lock_objects = FALSE,
  public = list(
    hash_function = NULL,
    hash_length_bits = NULL,
    reproducibility_mode = NULL, #!_RETURN
    .frozen_mode = NULL,
    .frozen_idx = NULL,
    .period = NULL,

    # Initialization logic covered by BeaconInterface

    initialize = function(...) {
      super$initialize(...)
    },

    #' @description
    #' Fetch, validate, and return the most recent pulse's output as an integer
    #' seed.
    #'
    #' Combines `get_latest_pulse()` and `validate_pulse()` into a single
    #' convenience call. The raw `outputValue` field of the pulse is converted
    #' to an integer vector via `to_raw()` before being returned.
    #'
    #' @param chain `character(1)` or `numeric(1)`. The chain to query.
    #'   Accepts either a numeric chain index or the special string `"last"`
    #'   (default), which resolves to the most recently active chain.
    #'
    #' @return An integer vector derived from the pulse's `outputValue` field.
    #'   The length of the vector corresponds to `hash_length_bytes`.
    #'
    #' @section Errors:
    #'   - Propagates any error raised by `validate_pulse()` if the fetched
    #'     pulse fails integrity checks.
    #'   - Propagates HTTP errors from `httr2` if the API request fails.
    #'
    #' @section Warnings:
    #'   - Issues a warning (via `validate_pulse()`) when the fetched pulse has
    #'     `pulseIndex == 1` and chain-linkage validation is therefore skipped.
    #'
    #' @examples
    #' beacon <- NISTBeacon$new()
    #'
    #' # Latest seed from the most recent chain
    #' seed <- beacon$get_latest_seed()
    #'
    #' # Latest seed from a specific chain
    #' seed <- beacon$get_latest_seed(chain = 1)
    get_latest_seed = function(chain = "last") {
      # 1. Fetch pulse
      pulse = self$get_latest_pulse(chain = chain)
      # 2. Validate pulse
      self$validate_pulse(pulse)
      # 3. Extract seed and convert to integer
      seed = as.integer(self$to_raw(pulse$outputValue))
      return(seed)
    },

    #' @description
    #' Fetch the most recent pulse from a given chain.
    #'
    #' Makes a `GET` request to `<api_base_url>/chain/<chain>/pulse/last` and
    #' returns the parsed pulse object. No validation is performed; call
    #' `validate_pulse()` on the result if integrity checking is required.
    #'
    #' @param chain `character(1)` or `numeric(1)`. The chain to query.
    #'   Accepts either a numeric chain index or the special string `"last"`
    #'   (default), which resolves to the most recently active chain.
    #'
    #' @return A named `list` representing the pulse object as returned by the
    #'   NIST Beacon API. Key fields include:
    #'   - `$outputValue` — the hex-encoded random output for this pulse.
    #'   - `$chainIndex` — the index of the chain this pulse belongs to.
    #'   - `$pulseIndex` — the position of this pulse within its chain.
    #'   - `$precommitmentValue` — a hash commitment to the *next* pulse's
    #'     local random value, used for forward-validation.
    #'   - `$listValues` — a data frame of previous pulses' `outputValue`
    #'     includes the columns "uri" (to make the HTTP request to retrieve
    #'     that pulse), "type" (e.g. `previous`, `year`, `month`, `day` or
    #'     `hour`. NIST v2.0 has a pulse period of 60 seconds, so `previous`
    #'     is the same as '1 minute ago')
    #' @section Errors:
    #'   - Raises an `httr2` error if the HTTP request fails (e.g. network
    #'     unavailable, non-2xx response).
    #'
    #' @examples
    #' beacon <- NISTBeacon$new()
    #'
    #' # Fetch from the most recent chain
    #' pulse <- beacon$get_latest_pulse()
    #' pulse$outputValue
    #'
    #' # Fetch from a specific chain
    #' pulse <- beacon$get_latest_pulse(chain = 1)
    get_latest_pulse = function(chain = "last") {
      response = httr2::request(paste0(
        self$api_base_url,
        "chain/",
        chain,
        "/pulse/last",
        collapse = ""
      )) |>
        httr2::req_perform()
      pulse = httr2::resp_body_json(response)$pulse
      return(pulse)
    },

    #' @description
    #' Fetch a specific pulse by chain index and pulse index.
    #'
    #' Unlike `get_latest_pulse()`, this method requires both arguments
    #' explicitly — there are no defaults. Use this when you need a
    #' reproducible reference to a particular pulse (e.g. for auditing or
    #' seeding a simulation with a historically fixed value).
    #'
    #' @param chain_index `numeric(1)`. The index of the chain containing the
    #'   desired pulse.
    #' @param pulse_index `numeric(1)`. The index of the pulse within the
    #'   specified chain.
    #'
    #' @return A named `list` representing the pulse object. See
    #'   `get_latest_pulse()` for a description of key fields.
    #'
    #' @section Errors:
    #'   - Raises an `httr2` error if the HTTP request fails, including when
    #'     the requested chain/pulse combination does not exist (HTTP 404).
    #'
    #' @examples
    #' beacon <- NISTBeacon$new()
    #'
    #' # Fetch the 42nd pulse from chain 1
    #' pulse <- beacon$get_pulse_by_index(chain_index = 1, pulse_index = 42)
    #' pulse$outputValue
    get_pulse_by_index = function(chain_index, pulse_index) {
      # For explicitly stating which pulse you want; error if none of the optional arguments are passed (i.e. no 'defaults'/'implied')
      response = httr2::request(paste0(
        self$api_base_url,
        "chain/",
        chain_index,
        "/pulse/",
        pulse_index,
        collapse = ""
      )) |>
        httr2::req_perform()
      pulse = httr2::resp_body_json(response)$pulse
      return(pulse)
    },

    #' @description
    #' Fetch the pulse that was current at a given Unix timestamp.
    #'
    #' Queries the NIST Beacon's time-based endpoint to retrieve whichever
    #' pulse was active at the specified moment. This is useful for
    #' reproducibly seeding a process from a wall-clock time.
    #' #_RETURN correct data type and mention str concat
    #' @param unix_time `numeric(1)`. A Unix timestamp (integer seconds since
    #'   1970-01-01 00:00:00 UTC) identifying the point in time for which the
    #'   corresponding pulse should be retrieved.
    #'
    #'   Note: human-readable date/time strings are not currently accepted.
    #'   Convert them first with, for example,
    #' #_RETURN correct this ex and mention str concat
    #'   `as.numeric(as.POSIXct("2024-01-01 12:00:00", tz = "UTC"))`.
    #'
    #' @return A named `list` representing the pulse object active at
    #'   `unix_time`. See `get_latest_pulse()` for a description of key fields.
    #'
    #' @section Errors:
    #'   - Raises an `httr2` error if the HTTP request fails, including when no
    #'     pulse exists for the given timestamp (e.g. a time before the beacon
    #'     was active).
    #'
    #' @examples
    #' beacon <- NISTBeacon$new()
    #'
    #' # Fetch the pulse active at a specific moment
    #' #_RETURN issue here re: numeric, etc
    #' t <- as.numeric(as.POSIXct("2024-06-01 00:00:00", tz = "UTC"))
    #' pulse <- beacon$get_pulse_by_timestamp(unix_time = t)
    #' pulse$outputValue
    get_pulse_by_timestamp = function(unix_time) {
      #!_RETURN add autoconversion utilities to allow users to put in human friendly date/times and auto convert to unix timestamps
      #! _RETURN in future schema there may be a distinction made
      #! that you can supply a chain index as well as timestamp

      # If greater than latest pulse's timestamp, return that pulse
      latest_pulse = self$get_latest_pulse()
      if (unix_time > .timeStamp_to_unix_time(latest_pulse$timeStamp)) {
        .inform(
          c(
            "!" = "Attempted to generate a pulse via a timestamp greater than the latest pulse's timestamp. Returning instead the latest pulse. Perhaps there is an error with conversion between datetime objects; note that NIST uses 'milliseconds since epoch' and not 'seconds since epoch'"
          ),
          class = "warning"
        )
        return(latest_pulse)
      }
      response = httr2::request(paste0(
        self$api_base_url,
        "pulse/time/",
        format(unix_time, scientific = FALSE),
        collapse = ""
      )) |>
        httr2::req_perform()
      pulse = httr2::resp_body_json(response)$pulse
      return(pulse)
    },

    get_pulse = function(
      chain_index = NULL,
      pulse_index = NULL,
      timestamp = NULL
    ) {
      pulse_can_be_identified = self$check_pulse_can_be_identified(
        pulse_index,
        chain_index,
        timestamp
      )
      .stopifnot(pulse_can_be_identified)
      if (!.any_is_null(chain_index, pulse_index)) {
        # If can be found via chain/pulse index
        pulse = self$get_pulse_by_index(
          chain_index = chain_index,
          pulse_index = pulse_index
        )
      }
      if (!is.null(timestamp)) {
        # If can only be found via timestamp
        pulse = self$get_pulse_by_timestamp(timestamp)
      }
      self$validate_pulse(pulse)
      return(pulse)
    },

    #' @description
    #' Validate the integrity of a pulse by checking its chain linkage.
    #'
    #' Performs two checks against the pulse immediately preceding the
    #'  one supplied:
    #'
    #' 1. **Previous-value check** — confirms that the `"previous"` entry in
    #'    the current pulse's `listValues` matches the `outputValue` of the
    #'    actual prior pulse fetched from the API.
    #' 2. **Pre-commitment check** — confirms that hashing the current pulse's
    #'    `localRandomValue` reproduces the `precommitmentValue` that was
    #'    published in the prior pulse. This is essential to proving there has
    #'    been no tampering in between pulses
    #'
    #'
    #' @param pulse A named `list` as returned by `get_latest_pulse()`,
    #'   `get_pulse_by_index()`, or `get_pulse_by_timestamp()`. Must contain at minimum
    #'   the fields `$chainIndex`, `$pulseIndex`, `$outputValue`,
    #'   `$localRandomValue`, and `$listValues`.
    #'
    #' @return `TRUE` (invisibly) if both checks pass, or if `pulseIndex == 1`
    #'   (see Warnings). Never returns `FALSE`; failure always raises an error.
    #'
    #' @section Errors:
    #'   - Raises an error with message `"Error; pulse could not be validated"`
    #'     if either the previous-value check or the pre-commitment check fails.
    #'     Possible root causes include:
    #'     - API inconsistency causing a mismatched prior pulse.
    #'     - Evidence of beacon tampering or non-malicious drift from protocol
    #'     - A schema change in the NIST Beacon API that alters field names or
    #'       structure.
    #'     - A gap in the pulse sequence (missing pulses in the chain).
    #'   - Propagates `httr2` errors if the request for the prior pulse fails.
    #'
    #' @section Warnings:
    #'   - Issues a warning when `pulse$pulseIndex == 1`, because there is no
    #'     prior pulse to validate against. In this case validation is skipped
    #'     and `TRUE` is returned unconditionally.
    #'
    #' @examples
    #' beacon <- NISTBeacon$new()
    #' pulse <- beacon$get_latest_pulse()
    #'
    #' # Validate a pulse before using its output
    #' beacon$validate_pulse(pulse)
    #'
    #' # Validate a historical pulse
    #' old_pulse <- beacon$get_pulse_by_index(chain_index = 1, pulse_index = 100)
    #' beacon$validate_pulse(old_pulse)
    validate_pulse = function(pulse) {
      #! _RETURN Name change to specify type of validation=check prev, not check skiplist
      # _LINENOTE: 30dc17c26b86.md
      chain_index = pulse$chainIndex
      pulse_index = pulse$pulseIndex
      if (pulse_index > 1) {
        # 1) Check reported 'previous value' matches actual previous value
        previous_pulse = self$get_pulse_by_index(
          chain_index = chain_index,
          pulse_index = pulse_index - 1
        )

        curr_pulse_record_of_previous_pulse_output_value = self$get_prev_value_from_pulse(
          pulse,
          type_ = "previous"
        )

        previous_pulse_output_value = previous_pulse$outputValue

        record_matches_previous = curr_pulse_record_of_previous_pulse_output_value ==
          previous_pulse_output_value

        # 2) Check previous pulse's precommitment value matches current pulse
        precommitment_checks_out = self$is_valid_hash(
          self$hash(pulse$localRandomValue),
          comparison_value = self$to_raw(previous_pulse$precommitmentValue)
        )
        if (record_matches_previous & precommitment_checks_out) {
          return(TRUE)
        } else {
          .error("Error; pulse could not be validated") #!_RETURN With descriptive error and guidance on what this means (possible user errors, possible beacon tampering, schema changes, gaps, etc)g
        }
      } else {
        .inform(
          c(
            "!" = "Validation ran on a pulse with index=1. Validity/tampering checks that verify based on previous pulses cannot be conducted. Passing validation..."
          ),
          class = "beacr.PulseValidationError"
        )
        return(TRUE)
      }
    },

    #' @description
    #' Hash a value using the beacon's configured hash function.
    #'
    #' The underlying algorithm (e.g. SHA-512) is determined at initialization
    #' by `BeaconInterface$resolve_hash_function()` reading the beacon's JSON
    #' configuration file, and is stored in `self$hash_function`. If `value`
    #' is not already a raw byte vector it will be coerced via `to_raw()` using
    #' `self$hash_length_bits` as the target width, and a warning will be
    #' issued.
    #'
    #' @param value The object to hash. Ideally a `raw` byte vector. Any other
    #'   type will trigger an automatic conversion attempt via `to_raw()` (see
    #'   Warnings).
    #'
    #' @return A `raw` vector containing the hash digest of `value`, with
    #'   length equal to `self$hash_length_bytes`.
    #'
    #' @section Warnings:
    #'   - If `value` is not a `raw` object, a warning of the form
    #'     `"Object '<value>' is not a raw byte object. Attempting to automatically convert..."`
    #'     is issued before coercion is attempted. If `to_raw()` cannot convert
    #'     the object it will raise its own error.
    #'
    #' @examples
    #' beacon <- NISTBeacon$new()
    #'
    #' # Hash a raw vector directly (no warning)
    #' raw_val <- as.raw(c(0x01, 0x02, 0x03))
    #' digest  <- beacon$hash(raw_val)
    #'
    #' # Hash a string — triggers automatic coercion warning
    #' digest <- beacon$hash("2F1A9B99A")
    hash = function(value) {
      # The function called here is determined programatically by
      # BeaconInterface's resolve_hash_function method. In the future, this
      # will also be able to be locally overridden by user options, but for
      # now the only way to define the bindings is via the json configuration
      # file in inst/extdata for each beacon
      if (!is.raw(value)) {
        #_LINENOTE: 30dc17c26b88.md
        .debug(
          "Object `{format(value)}` is not a raw byte object. Attempting to automatically convert..."
        )
        #_LINENOTE: 30dc17c26b87.md
        #!_RETURN Check if hexstring, else error
        if (!.is_hex_string(value)) {
          .error(
            "Object {format(value)} is not a hex string. Currently, only hashing raw byte vectors or character vectors of hex characters is supported.",
            class = "beacr.UnhashableTypeError"
          )
        }
        value = self$to_raw(value) #!_RETURN Possibly make more explicit by using hex_str_to_raw
      }
      return(self$hash_function(value))
    },

    verify_historical_seed = function(
      chain_index = NULL,
      pulse_index = NULL,
      timestamp = NULL,
      pulse_to_check = NULL,
      start_pulse = NULL
    ) {
      # 1. Make call to API for pulse
      pulse_to_check = pulse_to_check %||%
        self$get_pulse(
          chain_index = chain_index,
          pulse_index = pulse_index,
          timestamp = timestamp
        )
      # 2. Verify pulse's local random value matches the precommitment value of
      # the previous pulse
      locally_consistent = self$validate_pulse(pulse_to_check)
      stopifnot(locally_consistent)

      # 3. Verify chain was not altered in between pulse
      #! _RETURN In future, there should be an option to verify from an
      #! separate source (either database stored by user or separate API
      #! holding a separate database of previous pulses) as a motivated
      #! beacon operator could change the beacon front-end API to push out
      #! values that are consistent with a tampered past value...reading
      #! past values from a separate source verifies that the skiplist
      #! works as intended...

      #!_RETURN add progress bar and warn slow
      globally_consistent = self$skip_list_verification(
        pulse_to_check,
        start_pulse
      )
      .stopifnot(
        globally_consistent,
        "Could not verify chain integrity of pulse used for logged seed ($skip_list_verification returned {globally_consistent}"
      )

      .success("Successfully verified chain integrity of logged pulse!")
      return(TRUE)
    },

    get_timestamp_from_pulse = function(
      pulse,
      as_unix = FALSE
    ) {
      if (as_unix) {
        res = 1000 * as.integer(lubridate::as_datetime(pulse$timeStamp))
      } else {
        res = pulse$timeStamp
      }
      return(res)
    },

    #' Documentation: meniton the major headache with clamping and subpulse precision and etc; moved away from using timestamps and just pulse idxs
    #'  Used to clamp the start_time to
    #' last known timestamp to avoid
    #' any issues w/ sub-pulse-period
    #' precision
    #'  #! _RETURN Warn about automatically checking from curr time;
    #'  #! _RETURN if inputting start_time warn about milliseconds, etc
    skip_list_verification = function(
      pulse_to_check,
      start_pulse = NULL
    ) {
      if (is.null(start_pulse)) {
        start_pulse = self$get_latest_pulse(chain = pulse_to_check$chainIndex)
        .inform(c(
          "!" = "When verifying chain integrity of logged pulse, no starting pulse was passed. Starting chain verification with the latest pulse from its chain"
        ))
      } else {
        .stopifnot(
          {
            start_pulse$chainIndex == pulse_to_check$chainIndex
          },
          c(
            "Cannot verify a historical pulse using a starting pulse on a different chain",
            "Starting pulse chain index was {start_pulse$chainIndex}",
            "Pulse being verified chain index was {pulse_to_check$chainIndex}"
          )
        )
      }
      CHAIN_INDEX = start_pulse$chainIndex
      START_INDEX = start_pulse$pulseIndex
      STOP_INDEX = pulse_to_check$pulseIndex

      period = self$period
      if (identical(START_INDEX, STOP_INDEX)) {
        return(TRUE)
        .inform(
          "The pulse that is being verified is the same as the starting point. This likely means that you tried to read from a seed log less than {period} seconds after writing to the seed log. No verification can be done. Waiting {period} seconds before trying again..."
        ) #!_RETURN offer prompt menu to choose to wait or to abort. Also, in future, give options here for the case in which the Beacon is halted at a particular pulse index indefinitely
        Sys.sleep(60)
        return(self$skip_list_verification(
          pulse_to_check = pulse_to_check,
          start_pulse = start_pulse
        ))
      }
      num_skips = private$.estimate_number_of_API_calls_for_skiplist(
        pulse_to_check = pulse_to_check,
        start_pulse = start_pulse
      )

      extract_pulse_index_of_previous_pulses_from_current <- function(pulse) {
        return(
          sapply(pulse$listValues, function(x) {
            as.integer(stringr::str_match(x$uri, 'pulse/(\\d+)$')[2])
          })
        )
      }

      # Extract skiplist jump options from the starting pulse
      next_index_options = extract_pulse_index_of_previous_pulses_from_current(
        start_pulse
      )

      # Filter out any jumps that would go past the pulse you're checking
      next_index_options = next_index_options[next_index_options >= STOP_INDEX]

      if (length(next_index_options) > 0) {
        # If there are any valid jumps remaining from starting pulse after
        # filtering:
        curr_pulse = start_pulse
        curr_index = curr_pulse$pulseIndex

        cli::cli_progress_bar(
          format = "Verifying chain integrity {cli::pb_bar} {cli::pb_current}/{cli::pb_total} pulses | elapsed: {cli::pb_elapsed}",
          # total = num_skips
          total = START_INDEX - STOP_INDEX
        )
        num_skips_made = 0
        while (curr_index > STOP_INDEX) {
          # Continue jumping until you've jumped to the index the pulse
          # you wanted to check was at
          #!_RETURN check for super long-running loops and abort / force confirmation before starting

          next_index_options = extract_pulse_index_of_previous_pulses_from_current(
            curr_pulse
          )
          # Filter out any jumps that would go past the pulse you're checking
          next_index_options = next_index_options[
            next_index_options >= STOP_INDEX
          ]

          # Find the largest jump to minimize the number of jumps needed
          largest_jump_pulseIndex = min(next_index_options)
          list_idx_of_largest_jump = which.min(
            next_index_options
          )
          # Store the value that the jump is supposed to equal
          largest_jump_outputValue = curr_pulse$listValues[[
            list_idx_of_largest_jump
          ]]$value

          # Make the jump
          curr_pulse = self$get_pulse_by_index(
            CHAIN_INDEX,
            largest_jump_pulseIndex
          )
          rlang::try_fetch(
            {
              curr_indx = curr_pulse$pulseIndex
              num_skips_made = num_skips_made + 1
              # cli::cli_progress_update(set = num_skips_made)
              cli::cli_progress_update(set = (START_INDEX - curr_indx))
            },
            error = function(e) {
              .rethrow_if_not("Cannot find current progress bar", e)
              # Because my num_skips is an estimate, it may take more

              #!_RETURN In future, implement robust testing to use a more exact
              #! method and not have to handle possible miscalculation with
              #! a try/catch block
              invisible()
            }
          )

          # Check if the values line up
          stopifnot(curr_pulse$outputValue == largest_jump_outputValue)

          # Continue looping if so
          curr_index = curr_pulse$pulseIndex
        }
        .stopifnot(
          identical(curr_pulse$pulseIndex, STOP_INDEX),
          "Error in skip list method of verifying chain integrity: the skip list did not terminate on the index of the pulse being verified."
        )
        .stopifnot(
          identical(curr_pulse$outputValue, pulse_to_check$outputValue),
          "Could not verify chain integrity; pulse at pulse index {curr_pulse$pulseIndex} had an output value of {curr_pulse$outputValue} but was logged as having an output value of {pulse_to_check$outputValue}."
        ) #!_RETURN Replace with helper that verifies every field of the pulse list matches, not just outputValue

        .success("The beacon pulse logged is on a consistent chain of pulses")
        return(self$found_pulse(curr_pulse, pulse_to_check))
        #!_RETURN Validate that there is no n+1 error here
      } else {
        .error(
          "Error when validating pulse by skip list; the pulse index to be investigated is larger than all of the previous pulse values marked on the starting pulse. Perhaps you swapped the order? The pulse_to_check argument must be a pulse that occurred earlier than the start_pulse argument."
        )
      }
    },

    found_pulse = function(curr_pulse, pulse_to_check) {
      #! _RETURN all same
      same_indices = curr_pulse$pulseIndex == pulse_to_check$pulseIndex
      same_chain = curr_pulse$chainIndex == pulse_to_check$chainIndex
      same_output = curr_pulse$outputValue == pulse_to_check$outputValue
      return(all(same_indices, same_chain, same_output))
    },

    calculate_time_delta = function(
      pulse,
      start_time = NULL,
      direction = "backwards"
    ) {
      #! _RETURN In future add option to handle non-timestamp date parsing

      pulse_time = self$get_timestamp_from_pulse(pulse, as_unix = TRUE)

      if (direction == "backwards") {
        stopifnot(start_time > pulse_time)
      } else {
        stopifnot(pulse_time > start_time) #! _RETURN Instructive error messages
      }
      # Build an interval and extract the period
      interval = lubridate::interval(
        .ms_to_dt(start_time),
        .ms_to_dt(pulse_time)
      )
      period = lubridate::as.period(interval)

      # Pull each component from the Period object
      return(c(
        year = lubridate::year(period),
        month = lubridate::month(period),
        day = lubridate::day(period),
        hour = lubridate::hour(period),
        minute = lubridate::minute(period)
      ))
    },

    get_previous_pulse = function(pulse) {
      chain_index = pulse$chainIndex
      pulse_index = pulse$pulseIndex
      previous_pulse = self$get_pulse_by_index(
        chain_index = chain_index,
        pulse_index = pulse_index - 1
      )
      return(previous_pulse)
    },
    check_pulse_can_be_identified = function(
      pulse_index,
      chain_index,
      timestamp
    ) {
      if (is.null(pulse_index) & is.null(timestamp)) {
        .error(
          "Could not identify pulse; either pulse + chain index or timestamp must be passed. Likely called from skip_list_verification() via validate_historical_pulse().\npulse_index passed: {pulse_index}\ntimestamp passed: {timestamp}"
        )
      }
      if (is.null(chain_index) & !is.null(pulse_index)) {
        .error(
          "Could not identify pulse; pulse_index provided is `{pulse_index}` but no chain index was provided. Likely called from skip_list_verification() via validate_historical_pulse()"
        )
      }
      return(any(
        c(
          !.any_is_null(pulse_index, chain_index), # Can use pulse idx method
          !is.null(timestamp) # Can use timestamp method
        )
      ))
    },

    get_prev_value_from_pulse = function(pulse, type_ = "previous") {
      list = pulse$listValues
      idx <- which(sapply(list, \(x) x$type) == type_)
      return(list[[idx]]$value)
    },

    convert_to_unix_milliseconds = function(
      time = Sys.time(),
      offset = FALSE,
      offset_amount = 61
    ) {
      t = lubridate::as_datetime(time)
      t = (as.numeric(time) * 1000)
      if (offset) {
        # If you are trying to get the current latest time via timestamp,
        # offset=TRUE ensures that you are always querying at least 61 seconds
        # ago as NIST beacon has pulse period of 60 seconds. A more reliable
        # way to get the most updated time is using `get_latest_pulse()`. In
        # theory, if you call this exactly at time the new pulse should be
        # issued then you will get a stale pulse (the second-most recent)
        # instead of the most recent
        t = t - (offset_amount * 1000)
      }
      # Round down to nearest minute
      return(format(floor(t / 60000) * 60000, scientific = FALSE))
    },
    to_raw = function(value, bits = self$hash_length_bits) {
      res = .to_raw(value, bits = bits)
      return(res)
    }
  ),
  private = list(
    #' Estimate the max number of API calls one would need to verify using a skiplist that a historical pulse being verified is on the same chain as another pulse
    #'
    #' @param pulsediff An integer representing the difference in pulse indices of the reference pulse and the historical pulse
    .estimate_number_of_API_calls_for_skiplist = function(
      pulse_to_check,
      start_pulse
    ) {
      d1 = lubridate::as_datetime(pulse_to_check$timeStamp)
      d2 = lubridate::as_datetime(start_pulse$timeStamp)
      .stopifnot(
        d2 >= d1,
        c(
          "Cannot verify via skiplist a 'historical' pulse that occurred *after* the starting reference pulse on the chain.",
          " " = "Historical pulse timestamp is {d1}",
          " " = "Starting reference pulse timestamp is {d2}"
        )
      )
      period = lubridate::as.period(lubridate::interval(d1, d2))
      years = lubridate::year(period)
      months = lubridate::month(period)
      hours = lubridate::hour(period)
      days = lubridate::day(period)
      minutes = lubridate::minute(period)

      readout = glue::glue(
        "{years} years, {months} months, {days} days, {hours} hours, and {minutes} minutes"
      )
      .inform(
        c(
          "i" = "Historical pulse being verified was apparently issued {readout} ago..."
        )
      )

      num_skips = years + months + hours + days + minutes # To get upper bound
      .inform(
        c(
          "!" = "Will have to perform approximately {num_skips} API calls to verify the chain...at around 0.5s per call, this will take approximately {tolower(lubridate::seconds_to_period(0.5*num_skips))}"
        ) #!_RETURN This estimate is quite wrong at times; need to understand why by stepping through and seeing if it's due to time gaps/early pulse releases or what.
      )
      return(num_skips)
    }
  )
)
