# beacr

## Overview

`beacr` (pronounced ‘beaker’
([/ˈbiːkɚ/](https://speecher.org/?text=beaker))) improves the
transparency of analyses that use randomness in any form by providing a
random number generator that can be publicly audited after-the-fact.

`beacr` takes its name from the concept of **randomness beacons**, which
are secure public services that provide fresh random seeds on a fixed
schedule (for example, every minute). These beacons make it possible to
preregister an expected outcome that relies on some random process
**without knowing what the seed for that random process is beforehand**.
Beacons are also hash-chained, meaning that while you may not know what
the random seed is before running your analysis, anyone can verify what
the seed was after your analysis is completed.

A pipeline that uses `beacr` to report the results of analyses using
**verifiably random seeds** may look like this:

[![My
photo](reference/figures/beacr_flowchart.png)](https://github.com/cnsodano/beacr-pre-alpha/reference/figures/beacr_flowchart.png)

Typical use cases of `beacr` may be:

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
