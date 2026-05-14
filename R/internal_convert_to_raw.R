# Internal logic powering datatype conversions to and from `raw` atomic type.
# More than slightly overengineered, but allows for possible extension of
# accepting data in unusual formats, e.g. a sequence of bits represented in char
# ("0101110"). Conversion is necessary in the first place because it is more
# convenient for APIs to release data as JSON String values.
#
#!_RETURN In future, may replace a lot of this with openssl's internal functions e.g. openssl:::hex_to_raw

#' Dispatcher
#' @keywords conversionutils
#'@export
.to_raw <- function(value, bits) {
  if (is.raw(value)) {
    return(value)
  }
  if (.is_integer_like(value)) {
    return(.int_to_raw(value, bits))
  }
  if (is.character(value)) {
    if (length(value) > 1) {
      warning(
        "Detected a string vectors with vector length > 1. Combining the vector into one value using `paste(vec,collapse=\"\")`. This enforces a big-endian ordering; the most significant bit (MSB) of the resulting bit stream corresponds to the MSB of the first element of the vector, the least significant bit (LSB) to the LSB of the last element in the vector."
      )
      value = paste(value, collapse = "")
    }
    if (nchar(value) == 0) {
      # If value==""
      return(raw(0))
    }
    return(.str_to_raw(value, bits))
  }
  .error(
    "Unsupported datatype: value passed to `to_raw()` is not integer-like or character, instead has type {typeof(value)}"
  )
}

# Strings ----------------------------------------------------------------------
#-------------------------------------------------------------------------------
#' @concept conversionutils
.str_to_raw <- function(str_, bits) {
  # For extensibility; will catch case where string is literally
  # 0/1s of the correct length to match a hash value
  if (.is_binary_string(str_)) {
    return(.binary_str_to_raw(str_, bits))
  }
  if (.is_hex_string(str_)) {
    return(.hex_str_to_raw(str_, bits))
  }
  .error(c(
    "Value to be converted to `raw` type is detected as type `character` but is neither hex nor binary.",
    "value is: {str_)}"
  ))
}

#' @concept conversionutils
.is_binary_string <- function(x) {
  return(grepl("^[01]+$", x))
}

#' @concept conversionutils
.is_hex_string <- function(x) {
  return(grepl("^(0x)?[0-9A-Fa-f]+$", x))
}

#' @concept conversionutils
.binary_str_to_raw <- function(str, bits) {
  hash_length_bits = bits
  if (nchar(str) == hash_length_bits) {
    return(.convert_binary_string_to_bytes(str))
  }
  if (nchar(str) != (hash_length_bits / 4L)) {
    .error(
      "In str_to_raw a binary string was detected, but the length of {nchar(str)} was incompatible with the current hash_length_bits of `{hash_length_bits}`. The length of {nchar(str)} is also incompatible with representing the string as hexadecimal"
    )
  } else {
    .inform(
      c(
        "!" = "In str_to_raw a binary string was detected, but did not match the currently set hash length of `{hash_length_bits}`. Instead, it matched `{hash_length_bits/4}`, suggesting it is hexadecimal. This may be a rare case where the hex representation of the bit sequence includes only 0 and 1, or it may imply an error. Proceeding treating it as a hexadecimal string..."
      ),
      class = "warning"
    )
    return(.hex_str_to_raw(str, bits))
  }
}

#' @concept conversionutils
.convert_binary_string_to_bytes <- function(str) {
  if (nchar(str) %% 8 != 0) {
    .error(
      "Tried to convert a binary string to raw bytes type but the string length was not divisible by 8. String length was {nchar(str)}"
    )
  }
  # Split into chunks of 8 bits
  chunks <- regmatches(str, gregexpr(".{8}", x))[[1]]

  # Convert each chunk to a raw byte
  return(as.raw(strtoi(chunks, base = 2L)))
}

#' Convert from a hexadecimal character string to a sequence of raw hex bytes
#'
#' @param hex_str A string representing a bit sequence encoded in
#' hexadecimal. In practice, this will be a 64-character-long string that
#' represents the hexadecimal encoding of a 512-bit output of a hash function
#'
#' @return The raw byte pair sequence that the hex_str string is meant to
#' represent. In practice, this will be a vector of 64 byte-pairs encoded
#' in hexadecimal representing the raw form of the 512-bit sequence passed
#' as a string by hex_str
#'
#' @details
#' The values parsed from API calls to the NIST randomness beacon are in
#' string form. The bits used to represent ASCII strings are different from
#' the bits that those hexadecimal characters are meant to represent; e.g.
#' charToRaw("0") is 0x30(hex) corresponding to 00110000 but as.raw(0) is
#' 0x00(hex) corresponding to 00000000. So before hashing we must convert the
#' string to an integer (strtoi) and then take the raw form of that integer as
#' the object to hash
#' @concept conversionutils
#' @seealso [.to_raw] factory function which calls this function when a hex
#' string is detected
#'
#'
#' @examples
#' .hex_str_to_raw("00")
#' #> [1] 00
#' .hex_str_to_raw("FF")
#' #> [1] ff
#'
#' # More realistically,
#' .hex_str_to_raw("1C63CAF668ADC6E5B97903164EF5AE6DF7570F1AC76176F9B2703BAEA77F1295A63683B63D5AD08CC9E3E5A4D7E3D25C7DE1C31377F37212B7047560A94CBBA2")
#' #> [1] 1c 63 ca f6 68 ad c6 e5 b9 79 03 16 4e f5 ae 6d f7 57 0f 1a c7 61 76 f9 b2 70 3b ae a7 7f
#' #> [31] 12 95 a6 36 83 b6 3d 5a d0 8c c9 e3 e5 a4 d7 e3 d2 5c 7d e1 c3 13 77 f3 72 12 b7 04 75 60
#' #> [61] a9 4c bb a2
#'
#'
.hex_str_to_raw <- function(hex_str, bits) {
  .validate_hex_str_length(hex_str, bits) # Errors if invalid

  # Split into pairs of characters and convert each to a byte
  pairs <- regmatches(tolower(hex_str), gregexpr(".{2}", hex_str))[[1]]

  return(as.raw(strtoi(pairs, base = 16L)))
}

#' @concept conversionutils
.validate_hex_str_length <- function(hex_str, bits) {
  hash_length_bits = bits
  if (is.null(bits)) {
    .error("No value passed for bits when converted hex string")
  }
  bits_of_hex_str = .count_bits_of_hex_str(hex_str)
  if (is.null(bits_of_hex_str)) {
    browser()
  }
  if (bits_of_hex_str != hash_length_bits) {
    .error(
      "Value to hash was identified as a hex string but the length did not match the expected hash length, namely value length = `{nchar(hex_str)}` hex characters, corresponding to `{.count_bytes_of_hex_str(hex_str)}` bytes, while the current hash length is set to `{hash_length_bits}` bits, or `{hash_length_bits / 8}` bytes"
    )
  }
}

# Integers ---------------------------------------------------------------------
#-------------------------------------------------------------------------------

#' Check if a value can be represented as an integer without loss
#' @concept conversionutils
#'
#' @param x A value to check
#' @returns `TRUE` if `x` can be converted to an integer without changing its value
.is_integer_like <- function(x) {
  is.numeric(x) && !is.nan(x) && !is.infinite(x) && (x == as.integer(x))
}

#' @concept conversionutils
.int_to_raw <- function(int, bits) {
  if (length(int) > 1) {
    .validate_int_vec_length(int, bits)
    return(.ints_to_bytes(int))
  } else {
    return(.int_to_bytes(int))
  }
}

#' @concept conversionutils
.validate_int_vec_length <- function(vec, bits) {
  hash_length_bits = bits
  if (length(vec) != (hash_length_bits / 8L)) {
    .error(
      "Value to hash was identified as an integer vector but the length of the vector did not match the expected hash length, namely vector length = `{length(vec)}` while the current hash length is set to `{hash_length_bits}."
    )
  }
}

#' @concept conversionutils
.ints_to_bytes <- function(int_vec) {
  #' To be used when the value passed is a vector of integers representing
  #' byte pairs
  if (any(int_vec < 0 | int_vec > 255)) {
    .error(
      "While converting integer vector to raw bytes vector, at least one element of the integer vector was found exceed the integer bounds representable by 8 bits (0-255). If you are passing an integer vector, ensure each element represents an 8-bit integer."
    )
  }
  return(as.raw(int_vec))
}

#' @concept conversionutils
.int_to_bytes <- function(x, bits, size = 4, endian = "big") {
  #' To be used when the value passed is a single integer representing a 512-bit
  #' number
  .error(
    "Not yet implemented/tested converting a single integer into a byte stream"
  )
  # Size=4 because 32bit integers require 4 bytes to represent
  # res = writeBin(as.integer(x), raw(), size = size, endian = endian)
}

#' Helper for visualizing the raw bit form of a byte vector
#'
#' Note that R's rawToBits(...) function prints out bits in little-endian
#' order by default and since it uses the atomic 'bytes' data type for output
#' every bit will be represented as a hex byte, that is either 00 or 01. This
#' is confusing, so I use as.integer to convert the bytes into a single number
#' (00=>0, 01=>1) and rev() to turn from little-endian to big-endian by default
#' @concept conversionutils
.as_bits <- function(raw_value, bits, endian = "big") {
  if (!is.raw(value)) {
    value = .to_raw(value, bits)
  }
  if (endian != "big") {
    # If you want little-endian instead...
    rev <- function(x) x # No op, as R's default is little-endian
  }
  res = raw_value |> rawToBits() |> rev() |> as.integer()
  return(res)
}

#' @concept conversionutils
.raw_to_hex_str <- function(raw_vec) {
  return(
    paste(
      sprintf("%02X", as.integer(raw_vec)),
      collapse = ""
    )
  )
}

#' @concept conversionutils
.group_bits_into_bytes <- function(bits, endian = "big") {
  if (length(bits) %% 8 != 0) {
    .error("#!_RETURN 0 pad according to endian")
  }
  num_groups = length(bits) %/% 8
  res = character(num_groups)
  j = 1
  for (i in seq(num_groups)) {
    res[i] = paste0(bits[j:(j + 7)], collapse = "")
    j = (j + 8)
  }
  return(res)
}


# Because I got fed up doing mental math in validation blocks
.count_bits_of_hex_str <- function(hex_str) {
  return(nchar(hex_str) * 4)
}

.count_bytes_of_hex_str <- function(hex_str) {
  return(.count_bits_of_hex_str(hex_str) / 8)
}

#' Change the leading byte of a hash digest by one bit
#'
#' Used to test tampering with hash digests when verifying logs
.change_byte <- function(hash_digest) {
  #!_RETURN Make more programmatic: read bit ct from beacon settings logged in log's 'beacon' key
  bits = nchar(hash_digest) * 4

  raw_digest = .hex_str_to_raw(hash_digest, bits = bits)
  if (as.integer(raw_digest[1]) < 254) {
    raw_digest[1] = as.raw(as.integer(raw_digest[1]) + 1L)
  } else {
    raw_digest[1] = as.raw(as.integer(raw_digest[1]) - 1L)
  }
  return(.raw_to_hex_str(raw_digest))
}
