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

    # verify_historical_seed = function(...) {
    #   rlang::abort("Implementation left to interface implementers")
    # },

    get_pulse_by_index = function(...) {
      rlang::abort("Implementation left to interface implementers")
    },
    get_description = function() {
      rlang::abort("Implementation left to interface implementers")
    },

    get_latest_seed = function(...) {
      rlang::abort("Implementation left to interface implementers")
    },

    get_latest_pulse = function(...) {
      rlang::abort("Implementation left to interface implementers")
    },

    get_pulse_by_timestamp = function(...) {
      rlang::abort("Implementation left to interface implementers")
    },

    validate_pulse = function(...) {
      rlang::abort("Implementation left to interface implementers")
    },

    hash = function(...) {
      rlang::abort("Implementation left to interface implementers")
    }
  ),
)
