describe("converting hex string to raw", {
  it("returns a `raw` type", {
    expect_equal(typeof(.hex_str_to_raw("00", bits = 8)), "raw")
  })

  it("splits 0000 into two byte pairs", {
    expect_equal(length(.hex_str_to_raw("0000", bits = 16)), 2)
  })

  it("outputs uppercase hex chars", {
    is.uppercase <- function(x) {
      return(x == toupper(x))
    }

    # Manual bit arg pass
    expect_true(all(is.uppercase(.raw_to_hex_str(.to_raw("FFFF", bits = 16)))))

    # Inferred from options--- DEPRECATED, should now error
    withr::with_options(
      list(
        "beacr.hash_length_bits" = 8 * 4 # 4 bits per hex
      ),
      {
        expect_error(all(is.lowercase(.to_raw("FFFF1234")))) # No bits arg
      }
    )

    beacon = NISTBeacon$new()
    msg = "FFDD123456"
    beacon$hash_length_bits = 4 * nchar(msg)
    expect_true(all(is.uppercase(.raw_to_hex_str(beacon$hash(msg)))))
  })
})
#! _RETURN test errors for hash length incorrect length, etc
