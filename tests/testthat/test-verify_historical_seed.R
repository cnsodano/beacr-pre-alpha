# Testing the ability to verify that a value claimed to be beacon-generated did
# indeed come from that beacon, or at least
#
# For now, using NISTBeacon. In future, test the user-facing functional
# interface (i.e. not beacr::NISTBeacon$new()$verify_historical_seed() but
# simply beacr::verify_historical_seed())

describe("Unit tests: verifying previous pulses (internal functions)", {
  it("can verify previous pulse", {
    skip_if_offline()

    beacon = NISTBeacon$new()
    vcr::use_cassette("fetch_latest_pulse_to_verify_skiplist_of_n-1", {
      latest_pulse = beacon$get_latest_pulse()
    })

    latest_index = latest_pulse$pulseIndex
    latest_chain = latest_pulse$chainIndex

    vcr::use_cassette("perform_skiplist_of_n-1", {
      verified = beacon$verify_historical_seed(
        chain_index = latest_chain,
        pulse_index = latest_index - 1,
        timestamp = NULL,
        start_pulse = latest_pulse
      )
    })
    expect_true(verified)
  })
  it("can verify pulse 3 pulses back", {
    skip_if_offline()

    beacon = NISTBeacon$new()
    vcr::use_cassette("fetch_latest_pulse_to_verify_skiplist_of_n-3", {
      latest_pulse = beacon$get_latest_pulse()
    })
    latest_index = latest_pulse$pulseIndex
    latest_chain = latest_pulse$chainIndex

    vcr::use_cassette("perform_skiplist_of_n-3", {
      verified = beacon$verify_historical_seed(
        chain_index = latest_chain,
        pulse_index = latest_index - 3,
        timestamp = NULL,
        start_pulse = latest_pulse
      )
    })
    expect_true(verified)
  })
  it("can verify a pulse over a year back", {
    skip_if_offline()

    beacon = NISTBeacon$new()
    vcr::use_cassette("fetch_latest_pulse_to_verify_skiplist_of_over_a_year", {
      latest_pulse = beacon$get_latest_pulse()
    })
    latest_index = latest_pulse$pulseIndex
    latest_chain = latest_pulse$chainIndex

    pulses_per_hour_on_avg_with_no_gaps = 60
    pulses_per_day = pulses_per_hour_on_avg_with_no_gaps * 24
    pulses_per_month_high_bound = pulses_per_day * 31
    pulses_per_year_high_bound = pulses_per_month_high_bound * 12

    vcr::use_cassette("perform_skiplist_of_over_a_year", {
      verified = beacon$verify_historical_seed(
        chain_index = latest_chain,
        pulse_index = latest_index - ceiling(1.5 * pulses_per_year_high_bound),
        timestamp = NULL,
        start_pulse = latest_pulse
      )
    })
    expect_true(verified)
  })
})


test_that("Attempting to generate a pulse from timestamp in the future (or more recent than the API has caught up to) issues warning and returns most recent pulse", {
  skip()
  #!_RETURN In future implement
  # Get most recent, check index
  # try to
  # Be lenient; may be issues of millisecond difference in when the two are called?
})
