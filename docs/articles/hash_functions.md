# Hash Functions

`beacr` uses Secure Hash Algorithm (SHA) functions to verify that
external preregistration files have not been tampered with. This family
of functions offer certain desirable security guarantees, the most
important one for this context being **preimage resistance** which is a
property defined by the U.S. [National Institute of Standards and
Technology](https://csrc.nist.gov/projects/hash-functions) as: **“Given
a randomly chosen hash value, it is computationally infeasible to find
an input message that hashes to this hash value.”**

This means that once a preregistration file (the input message) is
published and the hash is recorded (namely, by mixing it in with the
seed pulse) there is practically no way one could change the content of
the file they use as a preregistration and still have that new file
produce the same recorded hash.¹ As a result, any attempt after-the-fact
to change the file, even by a small amount, will result in a different
seed produced by `beacr`.

For example, given the ‘preregistration’ statement, of “There will be a
significant effect of x on y”, one may want to retroactively change
their registration to make their original hypothesis seem to fit with
the results of the experiment. In this case, the ‘small change’ would be
adding the word ‘not’

``` r

# Hashing a toy example preregistration
openssl::sha256("There will be a significant effect of x on y")
#> [1] "e001e026df1b099d5470dabf04d23c84948ed3608238cd1254be9994ff3964da"
```

Compared to:

``` r

# Changing the content even slightly results in a completely different output
openssl::sha256("There will not a significant effect of x on y")
#> [1] "c40d41dd75ddc8a9169e9869a6fbb315aa3eec84244e2bcee3d9b8df5dc8a945"
```

Another consequence of this is that despite concatenating user-defined
input (the preregistration) with the random beacon output, we need not
worry about the preregistration influencing the resulting random number.

For example, using a toy example where the beacon produces only a single
bit of randomness and the rest of the input is completely determined by
our preregistration:

``` r

# Hashing a toy example preregistration
preregistration = openssl::sha256("I am very interested in manipulating the output to result in a seed I desire")

# The toy case where the preregistration has the MOST opportunity for influence
# possible; there is only a single bit that is NOT pre-determined
dummy_pulse1 = as.raw(0)

# Custom helper converts datatypes to raw before concatenating to avoid
# coercion
concatenated = c(beacr:::.hex_str_to_raw(preregistration, bits = 256), dummy_pulse1)

resulting_seed = openssl::sha512(concatenated)
resulting_seed
#> sha512 b4:57:44:5e:be:ef:f0:8e:3b:98:b0:dd:b1:48:5d:51:63:b8:7a:1d:19:80:95:b9:29:35:07:26:55:7c:a3:7b:6c:1e:d0:10:00:54:69:67:e8:8b:94:dc:55:fd:09:8b:ae:3e:79:24:b5:e4:a3:35:84:9e:70:36:e7:09:82:5d
```

Note that when the single bit of randomness offered by the dummy pulse
changes, we get a completely different outcome

``` r

# When changing a single bit (flipping the dummy pulse from 0 to 1)
dummy_pulse2 = as.raw(1)

# Custom helper converts datatypes to raw before concatenating to avoid
# coercion
concatenated = c(beacr:::.hex_str_to_raw(preregistration, bits = 256), dummy_pulse2)

resulting_seed = openssl::sha512(concatenated)
resulting_seed
#> sha512 bb:72:ed:21:de:7e:ea:34:5a:59:4c:65:d8:89:3a:49:12:56:43:ba:8e:1c:ad:bd:d4:04:87:81:d9:5b:dd:fa:a9:f9:e6:4b:cf:5f:ec:58:46:e0:80:90:d8:ab:62:54:54:b4:c9:ce:19:00:53:bc:89:2b:fd:9a:32:21:0a:be
```

In practice, the difference between two pulses is much larger than a
single bit (for the NISTBeacon, the random number generated contains 512
bits). Despite knowing the first 256 bits of our input into the hash
function, the next 512 bits (from the Beacon) results in an unbiased
outcome.

A note on rigor

*This has been a very non-rigorous explanation, namely while a small
difference in input can result in a large different in output, I did not
show that any differences in output are not **correlated** with the
change in input. This is beyond the scope of this package, as I assume
and hope you are using `beacr` to generate a single seed for a
Pseudo-Random Number Generator (PRNG), instead of using it as a PRNG
itself. After seeding the PRNG with a random number from `beacr` (which
is computationally infeasible to ‘game’), you should rely on the
statistical properties of your PRNG algorithm to ensure the initial
preregistration has no influence over the sequence of random numbers
used in the analysis thereafter.*

## How the preregistration is mixed with the Beacon pulse

The formula for determining the seed produced when a preregistration
file is provided is:

`seed = HASH_512( HASH_256(preregistration) || BEACON_512 )`

*where `||` means concatenation of the binary values, not bitwise
`OR`*  
*where BEACON_512 is the 512 bit output of the beacon*  
*where HASH_xxx is the SHA-family hash function*

  
  

#### Notes

1.  Even if you somehow use brute force to find another input that
    hashes to the same hash value as your original preregistration, even
    then it is extraordinarily unlikely that that new input would be
    intelligible in the language of the original preregistration.
