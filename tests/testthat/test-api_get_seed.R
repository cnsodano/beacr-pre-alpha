# Tests for specific `get_seed` behavior not tested by test-seed_log.R
# e.g. acquiring pulses other than the most recent

.check_verification_msgs <- function(msgs) {
  # Assert
  expect_match(
    msgs[1],
    regexp = "i Detected seed log file at path"
  )
  expect_match(
    msgs[2],
    regexp = "i Verifying the logged pulse can be recreated...\n"
  )
  expect_match(
    msgs[3],
    regexp = "v The beacon pulse logged matches the beacon pulse issued at the logged timestamp\n"
  )
  expect_match(
    msgs[4],
    regexp = "i Verifying the chain integrity of the logged pulse...\n"
  )
  expect_match(
    msgs[5],
    regexp = "! When verifying chain integrity of logged pulse, no starting pulse was passed. Starting chain verification with the latest pulse"
  )
  expect_match(
    msgs[6],
    regexp = "i Historical pulse being verified was apparently issued"
  )
  expect_match(
    msgs[7],
    regexp = "! Will have to perform approximately \\d+ API calls to verify the chain..."
  )
  expect_match(
    msgs[length(msgs) - 5],
    regexp = "v The beacon pulse logged is on a consistent chain of pulses\n"
  )
  expect_match(
    msgs[length(msgs) - 4],
    regexp = "v Successfully verified chain integrity of logged pulse!\n"
  )
  expect_match(
    msgs[length(msgs) - 3],
    regexp = "! Preregistration was not able to be found from the log"
  )
  expect_match(
    msgs[length(msgs) - 2],
    regexp = "! Continuing verification assuming no preregistration made.\n"
  )
  expect_match(
    msgs[length(msgs) - 1],
    regexp = "v Random seed logged is consistent with the logged preregistration and logged beacon pulse"
  )
  expect_match(
    msgs[length(msgs)],
    regexp = "v Successfully verified log! Returning reproducible seed...\n"
  )
}

describe("acquiring historical pulses", {
  it("Can acquire an early pulse on a chain", {
    .with_tempdir({
      # First write to the log
      seedA = beacr::get_seed(chain_index = 2, pulse_index = 2)

      # Then read from the log; will require verifying historical seed
      vcr::use_cassette("get_seed_to_acquire_chain_2_pulse_2", {
        msgs = capture_messages({
          seedA = beacr::get_seed(chain_index = 2, pulse_index = 2)
        })
      })

      # Assert
      .check_verification_msgs(msgs)
    })
  })
})

describe("Integration test: verifying previous pulse using api_get_seed function", {
  it("Correctly verifies a historical pulse from prior established seed log", {
    historical_pulse_seed_log_path = test_path(
      "fixtures",
      "historical_pulse_seed_log.json"
    )

    vcr::use_cassette("get_seed_to_acquire_chain_2_pulse_100", {
      msgs = capture_messages({
        # Read from historical log
        seedA = beacr::get_seed(log_file = historical_pulse_seed_log_path)
      })
    })
    .check_verification_msgs(msgs)
  })
  it("Correctly rejects a tampered historical pulse from prior established seed log", {
    tampered_historical_log_file_path = test_path(
      "fixtures",
      "tampered_historical_pulse_seed_log.json"
    )

    # Write new seed log
    expect_error(class = "beacr.InvalidOutputWithPreregistrationError", {
      vcr::use_cassette("validating_tampered_historical_log", {
        beacr::get_seed(
          log_file = tampered_historical_log_file_path,
        )
      })
    })
  })
})
