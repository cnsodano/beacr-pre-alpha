describe("NISTBeacon", {
  describe("$hash", {
    it("throws error if trying to hash non-hexstring", {
      beacon = NISTBeacon$new()
      expect_error(
        {
          beacon$hash("")
        },
        class = "beacr.UnhashableTypeError"
      )
      expect_error(
        {
          beacon$hash("not a hexstring")
        },
        class = "beacr.UnhashableTypeError"
      )
    })

    it("produces the same output as openssl sha512", {
      #! NOTE: this test may be volatile in the future if NIST
      #! changes the algorithm they use for hashing.

      beacon = NISTBeacon$new()
      hash1 = beacon$hash(raw(0))
      expect_identical(
        unclass(hash1),
        unclass(openssl::sha512(raw(0)))
      )

      msg2 = "010101"
      #!_RETURN Assert that a conversion to raw occurs and
      #! then check that the value matches
      beacon$hash_length_bits = nchar(msg2) * 4
      hash2 = beacon$hash(beacon$to_raw(msg2))
      expect_identical(
        unclass(hash2),
        unclass(openssl::sha512(openssl:::hex_to_raw(msg2)))
      )

      # Works for length of text is > 512 bits (of hex; 4bits/char => 128)
      #!_RETURN Assert that a conversion to raw occurs and
      #! then check that the value matches
      hash_bit_length = 512
      msg3 = strrep("F", 1 + ((hash_bit_length) / 4))
      beacon$hash_length_bits = nchar(msg3) * 4
      hash3 = beacon$hash(msg3)
      expect_identical(
        unclass(hash3),
        unclass(openssl::sha512(openssl:::hex_to_raw(msg3))),
      )
    })

    it("passes internal checks", {
      beacon = NISTBeacon$new()
      #!_RETURN
      beacon$hash_length_bits = 4 * 4
      hash1 = beacon$hash("1a2f")
      expect_true(beacon$is_valid_hash(hash1))
    })

    it("validates when comparison value is equal", {
      beacon = NISTBeacon$new()
      #!_RETURN
      beacon$hash_length_bits = 4 * 4
      hash1 = beacon$hash("1a2f")
      hash2 = beacon$hash("1a2f")
      expect_true(beacon$is_valid_hash(hash1, comparison_value = hash2))
    })

    it("does not validate when invalid comparison value", {
      beacon = NISTBeacon$new()
      #!_RETURN
      beacon$hash_length_bits = 4 * 4
      hash1 = beacon$hash("1a2f")
      hash2 = beacon$hash("1a2e")
      expect_false(beacon$is_valid_hash(hash1, comparison_value = hash2))
    })
  })

  describe("$is_valid_hash", {
    it("passes when comparing a pulse_i to pulse_i-1's precommittment value", {
      #! NOTE: This is testing the precommitment scheme of the
      #! BEACON ITSELF, and is not to be confused with the user
      #! preregistration feature that beacr provides. Read
      #! the NIST v2 manual for more information
      #! #!_RETURN Provide page references

      # Pulse i-1
      vcr::use_cassette("fetch_v_2_chain_1_pulse_1", {
        beacon = NISTBeacon$new()
        pulse_a = beacon$get_pulse_by_index(chain_index = 1, pulse_index = 1)
      })

      # Pulse i
      vcr::use_cassette("fetch_v_2_chain_1_pulse_2", {
        beacon = NISTBeacon$new()
        pulse_b = beacon$get_pulse_by_index(chain_index = 1, pulse_index = 2)
      })

      pulse_a_precommit = pulse_a$precommitmentValue
      pulse_b_randLocal = pulse_b$localRandomValue

      expect_true(beacon$is_valid_hash(
        beacon$hash(pulse_b_randLocal),
        comparison_value = beacon$to_raw(pulse_a_precommit)
      ))
    })
  })
})
