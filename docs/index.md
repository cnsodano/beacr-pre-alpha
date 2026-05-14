# beacr

## Overview

`beacr` (pronounced ‘beaker’
([/ˈbiːkɚ/](https://speecher.org/?text=beaker){\_target=“blank”}))
improves the transparency of analyses that use randomness in any form by
providing a random number generator that can be publicly audited
after-the-fact.

`beacr` takes its name from the concept of “randomness beacons”, which
are secure public services that provide fresh random seeds on a fixed
schedule (for example, every minute). These beacons make it possible to
preregister an expected outcome that relies on some random process
**without knowing what the seed for that random process is beforehand**.
Beacons are also hash-chained, meaning that while you may not know what
the random seed is before running your analysis, anyone can verify what
the seed was after your analysis is completed.

Typical use cases of this tool may be:

- Randomization of clinical trial participants into intervention groups
- Transparent random audit selections
  - For example, auditing research papers for research
    integrity/reproducibility checks
- Public coin flips
- Transparently reporting the random seeds set for machine learning
  algorithms, cross validation splits, etc

`beacr` seeks to help eliminate the possibility for ‘**seed-hacking**’,
a type of ‘p-hacking’ where you change the random seed used in a
stochastic algorithm until the result of running that algorithm matches
your hypothesis[^1]

### Typical usage pattern

``` r

library(beacr)
seed = beacr::get_seed()
set.seed(seed)
# Continue with reproducible random processes...
```

See [this
vignette](https://github.com/cnsodano/beacr-pre-alpha/basic_usage.md)
for more examples of typical usage patterns

## Beacons

Currently, the only beacon supported is the [National Institute of
Standards and Technology (NIST) Interoperable Randomness Beacon
(v2.0)](https://csrc.nist.gov/projects/interoperable-randomness-beacons/beacon-20)
developed by the Cryptographic Technology group at NIST, the same
department that developed the [Secure Hash Algorithm
(SHA)](https://en.wikipedia.org/wiki/Secure_Hash_Algorithms) and hosted
the competition that resulted in the development of the [Advanced
Encryption Standard
(AES)](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard).

More on the NIST Beacon

The NIST beacon v2.0 issues a ‘pulse’ every 60 seconds which can be
accessed by a public API returning a JSON data object which includes
metadata about the pulse as well as a fresh random number.

The main security feature that the NIST beacon employs that is relevant
for the typical user of this package (there are many beyond the scope of
this documentation) is hash-chaining:

- Each pulse is part of a chain. Every pulse provides a random number
  generated internally that is then combined with all of the metadata
  about the chain (including among other things the previous pulse’s
  output) to produce the final output.
- As a result, any attempt to alter the record of a previous pulse will
  be inconsistent with all future pulses in that chain
  - This does not prevent a motivated agent with the ability to alter
    **all** records in the NIST database from spoofing a historical
    record, but it does mean that any alterations to the NIST database
    can be detected as long as an external trusted copy of that chain is
    preserved
- The default chain index currently used is chain 2 which started in
  2022. 

**Resources:**

- [NIST Beacon info
  page](https://csrc.nist.gov/projects/interoperable-randomness-beacons)
- [NIST Beacon simple API
  documentation](https://csrc.nist.gov/Projects/interoperable-randomness-beacons/beacon-20)
- The formal schema for the v2.0 beacon can be found in
  `/inst/extdata/beacon_schemas/NIST_v_2-0_schema.xsd`
- The formal reference manual can be found
  [here](https://doi.org/10.6028/NIST.IR.8213-draft).
  - This document is both highly technical document and oddly vauge in
    that it describes in depth both the current NIST beacon version’s
    API but also what properties randomness beacons ought to have. A
    much more approachable and streamlined explanation can be found in
    presentation slides posted by one of the manual’s authors
    [here](https://csrc.nist.gov/csrc/media/Presentations/2024/web3rand-pulses-of-unpredictability/images-media/20240618-W3Rand-Virtual-Workshop-NIST-Ref-Rand-Beacons.pdf)

There are other open source client libraries for the NIST Beacon that
I’ve not yet used, but may be worth checking out:

- Python: [nistbeacon](https://github.com/urda/nistbeacon)
- Javascript:
  [nist-randomness-beacon](https://github.com/chainpoint/nist-randomness-beacon)

Future directions for new Beacons

A major limitation of the current alpha version of `beacr` is relying on
only one randomness beacon. The developers of NIST’s beacon themselves
suggest that mixing (or
*[`beacr::swirl`](https://github.com/cnsodano/beacr-pre-alpha/reference/swirl.md)ing*)
beacons together provide a more robust seed generation method in the
event that any one beacon becomes unreliable. In future versions, I hope
to implement additional beacons, and I welcome contributions to this
end. Other beacons available at the moment are:

- [Distributed Randomness Beacon (drand)](https://drand.love/) from the
  [League of Entropy](https://blog.cloudflare.com/league-of-entropy/)
  - drand has client libraries for accessing their beacon via
    [Go](https://github.com/drand/drand) and
    [Javascript](https://github.com/drand/drand-client), but not R (to
    my knowledge)
- [The University of Colorado Boulder’s CURBy (CU Randomness
  Beacon)](https://random.colorado.edu/)
  - CURBy has an official
    [Javascript](https://github.com/buff-beacon-project/curby-js-client)
    client library, but no library for R (to my knowledge)

If you wish to contribute to this project, adding additional beacons is
a great place to start.

## Preregistrations and Publicly Verifiable random sampling

Generating a random seed is great, but the real strength of `beacr` lies
in verifying that the seed was, in fact, random. `beacr` does this using
preregistrations. A preregistration is a public statement made prior to
engaging in an activity that outlines how you will engage in that
activity (the protocol) and what your anticipated outcomes are (the
hypothesis). Preregistration of scientific experiments, for example,
supports verifying after-the-fact whether the protocol was followed or
not, and whether the results of that experiment support the researcher’s
initial hypothesis.

`beacr` makes preregistering the random seed selection process simple.
Pass in a link to an file uploaded to an Open Science Framework (OSF)
registration and `beacr` will perform a verification check that covers
the timestamp and file integrity of that registration.

``` r

library(beacr)
seed = beacr::get_seed(
  preregistration_identifier = "https://osf.io/yrp3f/files/4gzvx",
  preregistration_source = "OSF"
)
set.seed(seed)
# Continue with reproducible random processes that are 
# now tied to your preregistration...
```

Ideally you will have specified in your preregistration which beacon
pulse you will be using for your analysis¹, but if you’re just now
discovering `beacr` and want to apply it to an in-progress study that
you’ve already preregistered, you will be able to prove
lack-of-prior-knowledge as long as the registration was published before
the time you request your seed.

Note on terminology differences used by NIST

To keep in line with language familiar to my intended audience for this
package, I’ve used the term ‘preregistration’ to refer to commiting to
the protocol and/or outcome of an analysis prior to acquiring a pulse to
use to seed that analysis. The NIST Beacon manual refers to this as
‘committing upfront’ or a ‘commiting statement’. See section 7.2: “Ex
post facto-verifiable random sampling” in the [official reference
manual](https://doi.org/10.6028/NIST.IR.8213-draft)

#### Notes

1.  The reason it is ideal to pre-specify when you will acquire the seed
    is to prevent people from locally running their analyses every
    minute/day until they get a random pulse with a seed that works for
    their desired narrative and then selectively reporting that outcome.

[^1]: For a toy example of seed-hacking ML model training, see [this
    notebook](https://github.com/Jason2Brownlee/MachineLearningMischief/blob/main/examples/seed_hacking_cross_validation.md)
    by [Jason Brownlee](https://github.com/Jason2Brownlee)
