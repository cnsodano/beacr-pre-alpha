# Testing that writing to and reading from a seed log works as expected under
# normal testing circumstances. Uses public facing "get_seed" functions, not
# testing the class-specific implementation per se

describe("reading from seed log", {
  it("creates the seed_log in the temporary directory", {
    .with_tempdir({
      expect_false(.seed_log_exists())

      # Create seed log by first call, capturing messages
      msgs = capture_messages({
        seedA = get_seed(preregistration_identifier = NULL)
      })

      # Assert
      expect_true(.seed_log_exists())
    })
  })

  it("produces the correct messages when preregistration value is NULL", {
    .with_tempdir({
      # Create seed log by first call, capturing messages
      msgs = capture_messages({
        seedA = get_seed(preregistration_identifier = NULL)
      })

      # Assert
      expect_match(
        msgs[1],
        "Did not detect a seed log file. Writing one to"
      )
      expect_match(msgs[2], "No preregistration identifier passed")
      expect_match(
        msgs[3],
        "Pulse successfully acquired. Details written to log at"
      )
    })
  })

  it("writes 'null' to log when preregistration_identifier is NULL", {
    .with_tempdir({
      # Create seed log by first call, capturing messages
      msgs = capture_messages({
        seedA = get_seed(preregistration_identifier = NULL)
      })

      # Read seed log saved
      log_path = fs::path(getwd(), "beacr", "seed_log.json")
      log_ = jsonlite::read_json(log_path, simplifyVector = TRUE)

      # Assert
      expect_all_true(c(
        is.null(log_$preregistration_identifier),
        identical(log_$preregistration_hash, "")
      ))
    })
  })

  it("writes '' to log for prereg hash when preregistration_identifier is NULL", {
    .with_tempdir({
      # Create seed log by first call, capturing messages
      msgs = capture_messages({
        seedA = get_seed(preregistration_identifier = NULL)
      })

      # Read seed log saved
      log_path = fs::path(getwd(), "beacr", "seed_log.json")
      log_ = jsonlite::read_json(log_path, simplifyVector = TRUE)

      # Assert
      expect_equal(log_$preregistration_hash, "")
    })
  })

  it("produces the same output when preregistration value is NULL as when ''", {
    .with_tempdir({
      # Create seed log by first call, capturing messages
      msgs = capture_messages({
        seedA = get_seed(preregistration_identifier = NULL, Beacon = NISTBeacon)
      })

      # Read seed log saved
      log_path = fs::path(getwd(), "beacr", "seed_log.json")
      log_ = jsonlite::read_json(log_path, simplifyVector = TRUE)

      # Logged output matches the seed
      seed_reconstructed = .to_raw(
        log_$output_with_preregistration,
        bits = 512 # NISTBeacon v2.0
      )
      logged_output_with_prereg_matches_seed = identical(
        seedA,
        seed_reconstructed
      )

      # Extract the outputs
      output_w_prereg = log_$output_with_preregistration
      output_wo_prereg = log_$output_without_preregistration
      output_is_not_changed_when_null_prereg = identical(
        output_w_prereg,
        output_wo_prereg
      )
      expect_all_true(c(
        output_is_not_changed_when_null_prereg,
        logged_output_with_prereg_matches_seed
      ))
    })
  })

  it("issues error when preregistration is passed but no preregistration exists on log", {
    skip(message = "TestNotImplementedYet")
  })

  it("issues error when no valid OSF link is passed and source type is OSF", {
    skip(message = "TestNotImplementedYet")
  })

  it("issues error when source type other than OSF is passed (currently)", {
    skip(message = "TestNotImplementedYet")
  })

  it("issues error when starting pulse passed for verification is not on same chain", {
    skip(message = "TestNotImplementedYet")
  })
})


describe("writing to seed log", {
  it("emits the expected messages", {
    .with_tempdir({
      ## Create seed log by first call, capturing messages

      # Corresponding to slides for a talk I gave at PYMS Summer Symposium 2025
      prereg_id = "https://osf.io/mbcw5/files/yahfc"

      # Mock .prompt_menu to always select to download and verify file hash
      local_mocked_bindings(
        .prompt_menu = function(choices, title) {
          return(c(1L))
        },
        .package = 'beacr'
      )
      msgs = capture_messages({
        seedA = get_seed(
          preregistration_identifier = prereg_id,
          preregistration_source = "OSF"
        )
      })

      expect_match(msgs[1], "Did not detect a seed log file. Writing one to")
      expect_match(
        msgs[2],
        "Using preregistration value with identifier:`https://osf.io/mbcw5/files/yahfc` from source: `OSF`"
      )
      expect_match(
        msgs[3],
        "! Validating the identifier passed to .get_preregistration_OSF"
      )

      expect_match(
        msgs[4],
        "! Currently this package doesn't check if the file provided"
      )
      expect_match(
        msgs[5],
        "i Validating OSF file hash by downloading external preregistration file..."
      )
      expect_match(
        msgs[6],
        "Hash value reported by OSF's API matches the hash value of the actual file available for download from OSF"
      )
      expect_match(
        msgs[7],
        "View source of preregistration value at: `https://osf.io/mbcw5/files/osfstorage/686faff93ef3be547af6d5a8"
      )
      expect_match(
        msgs[8],
        "Pulse successfully acquired. Details written to log at .*seed_log.json"
      )
    })
  })
  it("logs the prereg ID and hash", {
    .with_tempdir({
      ## Create seed log by first call, capturing messages

      # Corresponding to slides for a talk I gave at PYMS Summer Symposium 2025
      prereg_id = "https://osf.io/mbcw5/files/yahfc"

      # Mock .prompt_menu to always select to download and verify file hash
      local_mocked_bindings(
        .prompt_menu = function(choices, title) {
          return(c(1L))
        },
        .package = 'beacr'
      )

      msgs = capture_messages({
        seedA = get_seed(
          preregistration_identifier = prereg_id,
          preregistration_source = "OSF"
        )
      })
      # Read seed log saved
      log_path = fs::path(getwd(), "beacr", "seed_log.json")
      log_ = jsonlite::read_json(log_path, simplifyVector = TRUE)

      expect_false(is.null(log_$preregistration_identifier))
      expect_false(is.null(log_$preregistration_hash))

      nonempty_string <- nzchar

      expect_true(nonempty_string(log_$preregistration_identifier))
      expect_true(nonempty_string(log_$preregistration_hash))
    })
  })
  it("logs a different value for output_with_prereg than for output_without_prereg", {
    .with_tempdir({
      ## Create seed log by first call, capturing messages

      # Corresponding to slides for a talk I gave at PYMS Summer Symposium 2025
      prereg_id = "https://osf.io/mbcw5/files/yahfc"

      # Mock .prompt_menu to always select to download and verify file hash
      local_mocked_bindings(
        .prompt_menu = function(choices, title) {
          return(c(1L))
        },
        .package = 'beacr'
      )
      msgs = capture_messages({
        seedA = get_seed(
          preregistration_identifier = prereg_id,
          preregistration_source = "OSF"
        )
      })

      # Read seed log saved
      log_path = fs::path(getwd(), "beacr", "seed_log.json")
      log_ = jsonlite::read_json(log_path, simplifyVector = TRUE)
      expect_false(identical(
        log_$output_with_preregistration,
        log_$output_without_preregistration
      ))
    })
  })
  it("logs the correct hash", {
    #!_RETURN Confirm again the correct hash for this file via local download
    .with_tempdir({
      ## Create seed log by first call, capturing messages

      # Corresponding to slides for a talk I gave at PYMS Summer Symposium 2025
      prereg_id = "https://osf.io/mbcw5/files/yahfc"

      # Mock .prompt_menu to always select to download and verify file hash
      local_mocked_bindings(
        .prompt_menu = function(choices, title) {
          return(c(1L))
        },
        .package = 'beacr'
      )
      msgs = capture_messages({
        seedA = get_seed(
          preregistration_identifier = prereg_id,
          preregistration_source = "OSF"
        )
      })

      # Read seed log saved
      log_path = fs::path(getwd(), "beacr", "seed_log.json")
      log_ = jsonlite::read_json(log_path, simplifyVector = TRUE)

      expect_identical(
        tolower(log_$preregistration_hash),
        "7d5cb2011ea1d9c6e829b7d45db59fc074d738006960e4fc5a4c89e0593f8e55"
      )
    })
  })
})

describe("preregistrations", {
  it("works", {
    .with_tempdir({
      testthat::local_mocked_bindings(
        .prompt_menu = function(choices, title) {
          return(c(1L))
        },
        .package = 'beacr'
      )
      # Publish a preregistration first on OSF that specifies your protocol
      # and hypothesized outcomes
      #
      # Note that this is not a preregistration but a demo file (actually a
      # talk I gave at PYMS Summer Symposium 2025)
      OSF_preregistration_file_link = "https://osf.io/mbcw5/files/yahfc"

      # Acquire an ex post facto verifiably reproducible seed that is
      # inseparably linked to your preregistration
      seed = beacr::get_seed(
        preregistration_identifier = OSF_preregistration_file_link,
        preregistration_source = "OSF"
      )

      # Set reproducible seed
      set.seed(seed)

      # Use reproducible seed
      expect_identical(length(rnorm(10)), 10L)
    })
  })
})
#!_RETURN Check behavior when user declines to download/verify file
