#' Public interface for implementing a new `beacr`-compatible Beacon object from
#' a R6 class.
#'
BeaconInterface <- R6::R6Class(
  classname = "BeaconInterface",
  lock_objects = FALSE,
  public = list(
    name = "",
    version = "",
    api_base_url = "",
    schema_url = "",
    schema_package_local_path = "",
    notes = "",
    hash_algorithm = NULL,
    hash_function = NULL,
    hash_length_bits = NULL,
    reproducibility_mode = NULL,
    .frozen_mode = NULL,
    .frozen_idx = NULL,

    #' @description
    #' Constructor method for new beacons. Defers settings of
    #' fields to default values found in the `beacons.json` spec file at
    #' `inst/extdata/beacons.json`. Each Beacon implementation should call
    #' `super$initialize(...)` to benefit from this logic. Any
    #'
    #' @details
    #' For each setting argument passed to the constructor, prioriy goes to the
    #' user-passed value, then to the globally set option if there is any, then
    #' to the package's default
    #'
    #' In theory this allows initializing>1 Beacon objects with differing
    #' settings for testing or combining beacons
    #'
    #' @seealso [.get_beacon_defaults()]
    initialize = function(...) {
      args = list(...)
      defaults = .get_beacon_defaults(class(self)[1])
      for (name in names(defaults)) {
        # Prioriy goes to the user-passed value, then to the globally
        # set option if there is any, then to the package's default
        #
        # In theory this allows initializing >1 Beacon objects with
        # differing settings for testing or combining beacons
        self[[name]] = .arg_passed(name, args) %||%
          .get_option(paste0(
            class(self)[1],
            '.',
            name,
            collapse = ""
          )) %||%
          defaults[[name]]
      }

      self$resolve_hash_function()
    },

    #' @description
    #' A resolver for selecting the library provider for the hash functions
    #' needed by a Beacon. This allows for less dependency on any specific hash
    #' library. To change libraries, update the 'current_hash_library' and
    #' 'hash_libraries' keys in `inst/extdata/package_settings.json`
    resolve_hash_function = function() {
      beacon_settings_path = system.file(
        "extdata",
        "beacons.json",
        package = "beacr"
      )
      beacon_settings = jsonlite::read_json(beacon_settings_path)

      hash_algorithm = beacon_settings$beacons_table[[class(self)[
        1
      ]]]$hash_algorithm

      package_settings_path = system.file(
        "extdata",
        "package_settings.json",
        package = "beacr"
      )
      package_settings = jsonlite::read_json(package_settings_path)
      current_hash_library = package_settings[["current_hash_library"]] %||%
        package_settings[["default_hash_library"]]

      current_hash_function = package_settings$hash_libraries[[
        current_hash_library
      ]][[hash_algorithm]]
      current_hash_function_name = current_hash_function$function_name
      current_hash_function_bit_length = current_hash_function$hash_length_bits
      current_hash_function_byte_length = current_hash_function$hash_length_bytes

      self$hash_function = self$hash_function %||%
        getExportedValue(
          current_hash_library,
          current_hash_function_name
        )
      self$hash_length_bits = self$hash_length_bits %||%
        current_hash_function_bit_length
      self$hash_length_bytes = self$hash_length_bits / 8
    },

    #' @description
    #' Hash a value according to the specifics (hash digest bit length, hash
    #' function, etc) of the particular beacon
    hash = function(value) {
      rlang::abort("Implementation left to interface implementers")
    },

    #' @description
    #' Convert a beacon value to a raw byte vector, mainly used to convert hex
    #' strings from Beacon APIs into R raw byte atomic vector types
    to_raw = function(value, bits = self$hash_length_bits) {
      rlang::abort("Implementation left to interface implementers")
    },

    #' @description
    #' Get a pulse from the Beacon.
    get_pulse = function(
      chain_index = NULL,
      pulse_index = NULL,
      timestamp = NULL
    ) {
      rlang::abort("Implementation left to interface implementers")
    },

    #' @description
    #' Verify that a hashed value is consistent with the specification for a
    #' Beacon, namely the bit length. Optionally, compare between two hash
    #' values to check for equality. Useful for Beacon-specific internal
    #' validity checks, e.g. checking that the hash of a NISTBeacon's pulse
    #' randLocal value matches the previous pulse's precommitmentValue
    is_valid_hash = function(hashed_value, comparison_value = NULL) {
      if (!is.null(comparison_value)) {
        (return(all(hashed_value == comparison_value)))
      }
      hash_length_bytes = self$hash_length_bytes
      return(
        (length(hashed_value) == hash_length_bytes)
        #! _RETURN Optionally additional validation steps here
      )
    },

    #' @description
    #' Verify that a previous seed logged is consistent on the pulse chain
    #' #!_RETURN Change to more specific name
    verify_historical_seed = function(...) {
      rlang::abort("Implementation left to interface implementers")
    }
  ),
)
