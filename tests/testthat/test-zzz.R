# Testing the .onload functionality

describe("Loading from first call, (never before loaded)", {
  it("creates the default data directory", {
    curr_data_dir = .get_option("data_dir_location")
    # Reset state to reflect never having loaded the package before
    expect_true(fs::dir_exists(curr_data_dir))
    .reset_data_dir(yes_to_all = TRUE)
    expect_false(fs::dir_exists(curr_data_dir))

    # Load in a fresh R session
    default_data_dir = callr::r(
      func = function() {
        library(testthat)
        devtools::load_all() #!_RETURN In future, update to load not from source
        default_data_dir = .get_option("data_dir_location")
        return(default_data_dir)
      },
      cmdargs = "--vanilla"
    )

    # Assert
    expect_true(fs::dir_exists(default_data_dir))
  })

  it("alerts user that the default log location is in workspace", {
    # Reset state to reflect never having loaded the package before
    .reset_data_dir(yes_to_all = TRUE)

    # Load in a fresh R session
    result = callr::r(
      func = function() {
        library(testthat)

        expect_null(getOption("beacr.data_dir_location"))

        msgs = capture_messages({
          devtools::load_all()
        })
        default_data_dir = .get_option("data_dir_location")

        # Assert
        expect_true(fs::dir_exists(default_data_dir))
        return(list(
          msgs = msgs,
          data_dir = default_data_dir
        ))
      },
      cmdargs = "--vanilla"
    )

    pkg = "beacr"

    # Assert
    expect_equal(result$msgs[1], glue::glue("ℹ Loading {pkg}"))
    expect_true(stringr::str_detect(
      string = result$msgs[2],
      pattern = glue::glue(
        "beacr: Creating debug log folder at:\n{fs::path(getwd(),'beacr')}"
      )
    ))
  })
})

describe("Loading after first load", {
  it(" has data directory already built", {
    # Makes sure one load has already occurred
    .setup_second_load()

    curr_data_dir = .get_option("data_dir_location")
    expect_true(fs::dir_exists(curr_data_dir))

    # Load in a fresh R session
    default_data_dir = callr::r(
      func = function(exterior_data_dir_path) {
        library(testthat)

        expect_true(fs::dir_exists(exterior_data_dir_path))
        devtools::load_all() #!_RETURN In future, update to load not from source

        default_data_dir = .get_option("data_dir_location")
        expect_equal(exterior_data_dir_path, default_data_dir)

        return(default_data_dir)
      },
      args = list(exterior_data_dir_path = curr_data_dir),
      cmdargs = "--vanilla"
    )

    # Assert
    expect_true(fs::dir_exists(default_data_dir))
  })

  it("alerts user that the default log location is in the workspace", {
    # Makes sure one load has already occurred
    .setup_second_load()

    # Load in a fresh R session
    result = callr::r(
      func = function() {
        library(testthat)

        msgs = capture_messages({
          devtools::load_all()
        })
        default_data_dir = .get_option("data_dir_location")
        return(list(
          msgs = msgs,
          data_dir = default_data_dir
        ))
      },
      cmdargs = "--vanilla"
    )

    pkg = "beacr"

    # Assert
    expect_equal(result$msgs[1], glue::glue("ℹ Loading {pkg}"))
    expect_true(stringr::str_detect(
      string = result$msgs[2],
      pattern = glue::glue(
        "beacr: Debug logs are being written to:\n{fs::path(getwd(),'beacr')}"
      )
    ))
  })
})

#! _RETURN In future, test .onUnload functionalty:
