#' Verify the contents of a seed log are internally consistent
#'
#' @param log_file Seed log file to use for verifying; when called as part of
#' `get_seed`, this will automatically be passed via the `log_file` argument of
#' that function. Useful if you wish to verify a log file other than the
#' default, e.g. if you are testing multiple seeds and writing multiple log
#' files as a result
#' @param start_pulse_for_skiplist To allow starting from a diff pulse than
#' latest on chain, i.e. if a known diversion from protocol or infiltration
#' occurred
#'
#' @details Currently uses a hash table variable labelled `.beacons`
#' that matches a beacon string to the corresponding R6 object
#'
#' @export
verify_log <- function(log_file, start_pulse_for_skiplist = NULL) {
  #!_RETURN make this more abstracted and move pulse-specific logic to Beacon class methods

  log_ = jsonlite::fromJSON(log_file, simplifyVector = FALSE)

  # ============================================================================
  # 1. ======= Recreate the pulse from the log =================================
  # ============================================================================
  .inform(c("i" = "Verifying the logged pulse can be recreated..."))
  ## Pull info needed to recreate pulse API call
  logged_pulse_chainIndex = log_$pulse$chainIndex
  logged_pulse_pulseIndex = log_$pulse$pulseIndex
  logged_pulse_timeStamp = .timeStamp_to_unix_time(log_$pulse$timeStamp)

  ## Redo call based on the pulse supposedly used; confirm that the pulse/
  ## chain index and output values match
  beacon = .beacons[[log_$beacon]]$new()

  # get_pulse will favor chain/pulse index over timestamp; more
  # reliable to be explicit due to confusion that may surround mistimed/
  # time gaps in pulses
  recreated_pulse = beacon$get_pulse(
    chain_index = logged_pulse_chainIndex,
    pulse_index = logged_pulse_pulseIndex,
    timestamp = logged_pulse_timeStamp
  )

  .stopifnot(
    recreated_pulse$outputValue == log_$pulse$outputValue,
    "Log is inconsistent. Pulse output recorded is `{log_$pulse$outputValue}`, but looking up the pulse returns a different value: `{recreated_pulse$outputValue}` "
  )
  .success(
    "The beacon pulse logged matches the beacon pulse issued at the logged timestamp" #!_RETURN Slightly more complicated than this; if log only uses chain/pulse index and not timestamp e.g.
  )
  # Should be unnecessary since outputValue is a concatenation of
  # every record in the pulse, but...
  .stopifnot(
    (recreated_pulse$pulseIndex == log_$pulse$pulseIndex) ||
      (recreated_pulse$chainIndex == log_$pulse$chainIndex),
    "Log is inconsistent. Log records the pulse used at timestamp `{logged_pulse_timeStamp} is chainIndex = {log_$pulse$chainIndex)} and pulseIndex={log_$pulse$pulseIndex}, but in when querying the API for that timestamp the pulse returned has chainIndex = {recreated_pulse$chainIndex)} and pulseIndex={recreated_pulse$pulseIndex}"
  )

  # ============================================================================
  # 2. ======= Verify the pulse is consistent with the chain it is on =========
  # ============================================================================
  .inform(c("i" = "Verifying the chain integrity of the logged pulse..."))
  beacon$verify_historical_seed(
    pulse_to_check = recreated_pulse,
    start_pulse = start_pulse_for_skiplist
  )

  # ============================================================================
  # 3. == Verify logged preregistration is consistent with external source =====
  # ============================================================================
  rlang::try_fetch(
    {
      .preregistration_exists(
        preregistration_identifier = log_$preregistration_identifier,
        preregistration_source = log_$preregistration_source
      )
      .inform(c("i" = "Detected a preregistration message in log."))
      recreated_out = beacon$to_raw(recreated_pulse$outputValue)
      recreated_output = beacon$hash(.concatenate_hashes(
        log_$preregistration_hash,
        recreated_out,
        bits_a = 256, #!_RETURN Make programmatic rather than hard-coded to NIST
        bits_b = 512 #!_RETURN Make programmatic rather than hard-coded to NIST
      ))

      .verify_preregistration_hash_is_consistent_with_random_seed_output(
        log_,
        recreated_output
      )

      .inform(
        c(
          "i" = "Verifying the logged preregistration is consistent with external source..."
        )
      )
      .verify_timestamp_and_hash_of_preregistration_identifier_from_external_source(
        log_
      )
      .success("Successfully verified log! Returning reproducible seed...")
      return(recreated_output)
    },
    beacr.PreregistrationNotFoundError = function(e) {
      logger::log_info(
        "Catching beacr.PreregistrationNotFoundError..."
      )
      #!_RETURN Implement strict mode turning this nonstopping fail into a
      #! blocking error
      .inform(c(
        "!" = "Preregistration was not able to be found from the log, preventing verification of preregistration. See the 'Preregistration' section in the Basic Usage vignette for more details: vignette('basic_usage', package='beacr')"
      ))
      .inform(c(
        "!" = "Continuing verification assuming no preregistration made."
      ))
      recreated_output <<- beacon$hash(beacon$to_raw(
        recreated_pulse$outputValue
      ))

      #!_RETURN Implement more tests for logic breaks here; this control flow
      #! shift has potential for bugs that let people skip verification
      #! and pass tampered logs through the system potentially avoiding
      #! detection
      .verify_preregistration_hash_is_consistent_with_random_seed_output(
        log_,
        recreated_output,
        no_prereg = TRUE
      )
      .success("Successfully verified log! Returning reproducible seed...")
      return(recreated_output)
    }
  )
}

.verify_preregistration_hash_is_consistent_with_random_seed_output <- function(
  log_,
  recreated_output,
  no_prereg = FALSE
) {
  valid = log_$output_with_preregistration == .raw_to_hex_str(recreated_output)
  if (no_prereg) {
    if (!valid) {
      .error(
        message = c(
          "No preregistration was passed, but the logged seed is not equivalent to the seed expected with no preregistration.",
          "Value logged: {log_$output_with_preregistration}",
          "Value expected: {.raw_to_hex_str(recreated_output)}"
        ),
        class = c(
          "beacr.InvalidOutputWithPreregistrationError",
          "beacr.InvalidLogError"
        )
      )
    }
  }
  .stopifnot(
    valid,
    "Log is inconsistent: output_with_preregistration was logged to be {log_$output_with_preregistration} but the output recreated from the logged pulse information was found to be {recreated_output}"
  )
  .success(
    "Random seed logged is consistent with the logged preregistration and logged beacon pulse value..."
  )
}

.verify_timestamp_and_hash_of_preregistration_identifier_from_external_source <- function(
  log_
) {
  #! _RETURN Poor design pattern but getting the precommit obj will run
  #! the hashing validation
  .inform(c(
    "i" = "Validating timestamp and hash of preregistration from external provider..."
  ))
  tryCatch(
    {
      preregistration = .get_preregistration(
        identifier = log_$preregistration_identifier,
        source = log_$preregistration_source
      )
    },
    error = function(e) {
      browser()
      if (
        grepl(
          "Invalid preregistration identifier",
          conditionMessage(e),
          ignore.case = TRUE
        )
      ) {
        invisible()
      } else {
        browser()
        stop(e) # re-throw other errors
      }
    }
  )

  .stopifnot(
    (preregistration$timestamp_of_preregistration <
      .timeStamp_to_unix_time(log_$pulse$timeStamp)),
    "Preregistration was published after the pulse, invalidating the preregistration. This is a fatal error that violates the principle of using a randomness beacon for public verification of prior commitment to an unknown random value"
  )
  .success(
    "Preregistration was published before the logged pulse timestamp"
  )
}
