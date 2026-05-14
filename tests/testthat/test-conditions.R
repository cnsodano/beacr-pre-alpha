test_that("creating a new condition without rlang_error class will still be able to catch error clas with try_fetch", {
  cnd <- structure(
    class = c("error", "condition"),
    list(message = "my message")
  )
  rlang::try_fetch(
    {
      rlang::cnd_signal(cnd)
    },
    error = function(e) {
      print(class(e))
    }
  )
  expect_true(TRUE)
})

test_that("can regex msg", {
  expect_error({
    rlang::try_fetch(
      {
        .error("this")
      },
      error = function(e) {
        if (stringr::str_match(e$message, "Cannot find current progress bar")) {
          .rethrow_if_not("Cannot find current progress bar", w)
        }
        print(class(e))
      }
    )
  })
})

test_that("tryfetching works", {
  # .inform(
  #   c(
  #     "!" = "Attempted to generate a pulse via a timestamp greater than the latest pulse's timestamp. Returning instead the latest pulse. Perhaps there is an error with conversion between datetime objects; note that NIST uses 'milliseconds since epoch' and not 'seconds since epoch'"
  #   ),
  #   class = c("error", "NYI")
  # )
  rlang::try_fetch(
    {
      .inform(
        c(
          "!" = "Attempted to generate a pulse via a timestamp greater than the latest pulse's timestamp. Returning instead the latest pulse. Perhaps there is an error with conversion between datetime objects; note that NIST uses 'milliseconds since epoch' and not 'seconds since epoch'"
        ),
        class = c("warning", "nyi")
      )
    },
    nyi = function(w) {
      print('this catch')
    },
    warning = function(w) {
      print("hi")
    }
  )
})
