# Unit tests for helpers in R/osf.R

describe("OSF preregistration-- common URL (GUID)", {
  it("acquires a file from a common URL using GUID, not api unique file ID", {
    local_mocked_bindings(
      .prompt_menu = function(choices, title) {
        return(c(1L))
      },
      .package = 'beacr'
    )

    # Corresponding to slides for a talk I gave at PYMS Summer Symposium 2025
    id = "https://osf.io/mbcw5/files/yahfc"

    expect_no_error({
      pr = .get_preregistration_OSF(id)
    })

    date_of_pr = .ms_to_dt(pr$timestamp_of_preregistration)
    expect_identical(2025, lubridate::year(date_of_pr))
    expect_identical(7, lubridate::month(date_of_pr))
    expect_identical(10L, lubridate::day(date_of_pr))
  })
})
