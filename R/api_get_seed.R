#' Get a new fresh seed from the latest pulse sent by a Beacon of choice.
#'
#' @returns A vector of raw bytes representing a random bitstream from a beacon #' pulse
#'
#' @param log_file A path to the file that the seed log will be saved at. Defaults to <WORKING DIRECTORY>/beacr/seed_log.json
#'
#' @param preregistration_identifier A string representing the unique resource identifier (URI) of an external resource that specifies a protocol or outcome that you have pre-committed to prior to requesting a seed. Combined with preregistration_source, this identifier allows verifying that the preregistration was published prior to the pulse being requested and ensures that later reproductions of analyses using this function for seeding are innately tied to the precommiteed protocol (via hash-concatenation). Currently only supports OSF API v2 file URIs.
#'
#' @param preregistration_source A string representing the provider of the external preregistration resource to be used for verifying precommitted claims/protocols. Currently only supports the Open Science Framework ("OSF").
#'
#' @param Beacon An R6 object implementing the `BeaconInterface` which provides all logic for requesting a fresh randomness pulse from a specific Beacon. Currently only supports `NISTBeacon` and is not intended to be passed by default, but experienced users can implement their own `Beacon` classes to extend support for a Beacon of choice.
#'
#' @param starting_pulse_for_verification See [verify_log] for details
#'
#' @param pulse_index The index of a pulse if you wish to get a seed from a particular pulse, instead of the most recent. Must be passed with chain_index. If integer/numeric, will be coerced to string during API call construction. If "last", will pull the most recent pulse on the chain
#'
#' @param chain_index The chain of a pulse if you wish to get a seed from a particular pulse, instead of the most recent. Must be passed with pulse_index. If integer/numeric, will be coerced to string during API call construction. If "last", will pull the most recently started chain
#'
#' @param timestamp double/char representing the UNIX time (milliseconds since epoch of 00:00:00 UTC on Thursday, 1 January 1970) of a pulse if you wish to get a seed from a particular pulse, instead of the most recent. Note: beware of using an integer type when working with timestamps as the base R maximum integer limit of ((2^31)-1) is too small to represent most dates measured in milliseconds without converting the timestamp to NA due to overflow
#'
#' @examples
#' # Out of box usage
#' seed = get_seed()
#' set.seed(seed)
#' randnorm(1)
#'
#' # Custom log file path for sharing reproducible files
#' workspace = getwd()
#' get_seed(log_file = fs::path(workspace, 'data', 'seed_log.json')
#'
#' # Using a preregistration
#' workspace = getwd()
#' # Using example from OSF "Welcome to Registrations" page: https://help.osf.io/article/330-welcome-to-registrations
#' OSF_preregistration_file_unique_id = "https://osf.io/wekmb/files/vc896"
#' get_seed(
#'   preregistration_identifier = OSF_preregistration_file_unique_id
#'   preregistration_source = "OSF"
#' )
#'
#' @details
#' By default a JSON log file will be created that records the following
#' information about the seed request:
#'   - The timestamp the pulse was requested,
#'   - The Beacon the pulse was requested from and details about the
#'     HTTP request made #!_RETURN implement
#'   - The pulse information adapted from the JSON API response of the Beacon
#'   - Optionally (and highly encouraged), information about a preregistration
#'     made prior to requesting a seed. More information about preregistrations
#'     can be found at the `Preregistration` section of the Getting Started
#'     vignette #!_RETURN link
#'
#' By default this log will be saved to the directory specified by the package
#' option "beacr.data_dir_location" which defaults to `<WORKSPACE>/beacr/` but a
#' log file path can be passed directly.  Call `beacr::where_is_seed_log()`` to
#' find where this file is stored.
#'
#' This file will be then be used on the next call to `get_seed(...)` to
#' 'replay' the recorded pulse request and verify that the contents of the log
#' are internally consistent (using `verify_log(...)`. If an identifier for an
#' external preregistration source is passed via preregistration_identifier and
#' preregistration_source, this resource will be downloaded and validated as
#' part of the verification process.  If using this function call as a source of
#' a verifiably random, reproducible seed, you should pass a local path (i.e.
#' relative to the workspace that the code using the seed will be found in and
#' shared) so that this log is available to others trying to reproduce the
#' pulse.
#'
#' The default Beacon can be found in the package directory under
#' `/inst/extdata/package_settings.json` and the details of all currently
#' supported beacons can be found at `/inst/extdata/package_settings.json`.
#' For advanced use, users can pass a custom Beacon object which is an instance
#' of and R6 class that implements the `R/BeaconInterface.R` interface.
#'
#' @seealso [verify_log]
#'
#' @export
get_seed <- function(
  log_file = NULL,
  preregistration_identifier = NULL,
  preregistration_source = c("OSF"),
  Beacon = NISTBeacon,
  pulse_index = NULL,
  chain_index = NULL,
  timestamp = NULL,
  starting_pulse_for_verification = NULL
) {
  if (!is.null(timestamp)) {
    .error(
      "Currently, `beacr` does not support verifying seeds acquired by timestamp. The logic to implement this is fully baked in, so contributions to extend this functionality are welcome! Pass a pulse/chain index to acquire and write a seed log for a pulse other than the latest."
    )
  }
  preregistration_source = match.arg(preregistration_source)
  # Get a directory to write/read seed log from
  data_dir = .get_option("data_dir_location")
  log_file = log_file %||% file.path(data_dir, "seed_log.json")
  #! _RETURN Prompt users to create directory if custom path passed that does
  #! not exist AND directory of path does not exist

  # If 'replaying' from log, i.e. not first call (reproducing/auditing the seed)
  if (file.exists(log_file)) {
    .inform(c(
      "i" = "Detected seed log file at path `{log_file}`, reading from that file (**NOT** generating new seeds). Call `reset_seed_log()` to purge this file and generate new seeds"
    ))

    recreated_output_with_preregistration_hash = verify_log(log_file)

    return(unclass(recreated_output_with_preregistration_hash))
  } else {
    # No log file yet; this is the first generation of the seed, log it to later

    .inform(c(
      "i" = "Did not detect a seed log file. Writing one to `{log_file}`"
    ))

    # Make API call to latest pulse
    beacon = Beacon$new() #!_RETURN implement beacon factory that pulls from options() and defaults to the default.json options
    # If passed arguments for specific pulse instead of defaulting to latest...
    if (!is.null(chain_index) & !is.null(pulse_index)) {
      if (!is.null(timestamp)) {
        .inform(
          c(
            "!" = "While trying to identify which pulse to acquire, two methods of distinguishing a pulse were passed:",
            " " = "1. chain_index: {chain_index} and pulse_index: {pulse_index}",
            " " = "2. timestamp = {timestamp}"
          ),
          footer = "Currently, `beacr` does not validate whether these are compatible (i.e. they point to the same pulse). In general, pulse/chain indices are much more reliable; proceeding using the chain/pulse indices instead of timestamp...",
          class = 'beacr.warning'
        )
      } else {
        .inform(c(
          "i" = "Detected an attempt to acquire a pulse other than the latest, requesting pulse at chain_index: {chain_index} and pulse_index: {pulse_index} instead..."
        ))
      }
    } else {
      # Defaults to latest
      chain_index = "last"
      pulse_index = "last"
    }
    pulse = beacon$get_pulse(
      chain_index = chain_index,
      pulse_index = pulse_index,
      timestamp = timestamp
    )
    now = .posix_to_NIST_UNIX(Sys.time())

    preregistration_hash = NULL
    # If supplied preregistration identifier, gather the preregistration
    rlang::try_fetch(
      {
        .preregistration_exists(
          preregistration_identifier = preregistration_identifier,
          preregistration_source = preregistration_source
        )
        .inform(c(
          "i" = "Using preregistration value with identifier:`{ preregistration_identifier}` from source: `{preregistration_source}`"
        ))
        preregistration = .get_preregistration(
          identifier = preregistration_identifier,
          source = preregistration_source
        )
        .inform(c(
          "i" = "View source of preregistration value at: `{preregistration$preregistration_viewing_link}`"
        ))
        #!_RETURN In future, use more sophisticated approach to auto-match the
        #! expected raw output size to the hash algorithm used by the prereg
        #! source, as they may not all be in hex
        preregistration_hash = .to_raw(
          preregistration$hash,
          bits = nchar(preregistration$hash) * 4 # 4 bits per hex char
        )
      },
      beacr.PreregistrationNotFoundError = function(e) {
        .nonstopping_fail(
          "No preregistration identifier passed, using pulse without preregistration. See the 'Preregistration' section in the Basic Usage vignette for more details: vignette('basic_usage', package='beacr')"
        )
        #! _RETURN
        preregistration_hash <<- raw(0)
      }
    )
  }

  # Construct log
  output_with_preregistration_hash = beacon$hash(.concatenate_hashes(
    preregistration_hash,
    beacon$to_raw(pulse$outputValue)
  ))
  output_without_preregistration = beacon$hash(beacon$to_raw(pulse$outputValue))

  log_ = list(
    beacon = class(beacon)[1],
    time_of_generation = now,
    pulse = pulse,
    preregistration_source = preregistration_source,
    preregistration_identifier = preregistration_identifier,
    preregistration_hash = .raw_to_hex_str(preregistration_hash),
    output_without_preregistration = .raw_to_hex_str(
      output_without_preregistration
    ),
    output_with_preregistration = .raw_to_hex_str(
      output_with_preregistration_hash # For readability
    )
  )

  # Write file
  # if (fs::dir_exists(fs::path_dir(log_file))) {
  jsonlite::write_json(
    log_,
    log_file,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )
  # } else {
  #   dir.create(fs::path_dir(log_file))
  # }
  .success(
    "Pulse successfully acquired. Details written to log at {log_file}"
  )

  return(unclass(output_with_preregistration_hash))
}
