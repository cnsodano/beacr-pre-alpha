
# beacr <img src="man/figures/logo.png" height="120" />
Check out the full documentation at the `beacr` package website [here](https://cnsodano.github.io/beacr-alpha/)

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

<div class="img-breakout">

<a href="man/figures/beacr_flowchart.png" class="glightbox">
<img src="man/figures/beacr_flowchart.png" alt="An image of a flowchart depicting the typical 'write', 'register', 'run', and 'reproduce' pipeline that the beacr package supports. From left to right: Write: protocol/hypotheses are written in a document, as well as code to produce some analysis output supporting that hypothesis. Register: files are registered with the Open Science Framework, created a locked record that cannot be re-written after registation. Run: beacr facilitates combining the pre-registered contents on the Open Science Framework servers with a time-specific random value from a randomness beacon pulse, producing a unique seed to be used to seed pseudo-random number generators used in the analysis script. When run, this produces a result. Reproduce: Re-running the analysis script re-collects the seed used by querying the randomness beacon and the Open Science Framework again, reconstructing the random seed, and re-seeding the analysis. Once the result is produced and matches the original output, results are confirmed."/>
</a>

</div>

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

[^1]: For a toy example of seed-hacking ML model training, see [this
notebook](https://github.com/Jason2Brownlee/MachineLearningMischief/blob/main/examples/seed_hacking_cross_validation.md)
by [Jason Brownlee](https://github.com/Jason2Brownlee)

## Installation

Currently, `beacr` is not yet available on CRAN. Install `beacr`
directly from GitHub using `pak`(recommended), `remotes`, or
`devtools`(deprecated)

#### pak

``` r
# install.packages("pak")
pak::pak("cnsodano/beacr-pre-alpha")
```

#### remotes

``` r
# install.packages("remotes")
remotes::install_github("cnsodano/beacr-pre-alpha")
```

#### devtools

``` r
# install.packages("devtools")
devtools::install_github('cnsodano/beacr-pre-alpha')
```

## Usage

### Typical usage pattern

``` r
library(beacr)
seed = beacr::get_seed()
set.seed(seed)
# Continue with reproducible random processes...
```

See `vignette("beacr")` for more examples of typical usage patterns

### Preregistrations and Publicly Verifiable random sampling

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
pulse you will be using for your analysis<sup>1</sup>, but if you’re
just now discovering `beacr` and want to apply it to an in-progress
study that you’ve already preregistered, you will be able to prove
lack-of-prior-knowledge as long as the registration was published before
the time you request your seed.

<details>

<summary>

Note on terminology differences used by NIST
</summary>

To keep in line with language familiar to my intended audience for this
package, I’ve used the term ‘preregistration’ to refer to commiting to
the protocol and/or outcome of an analysis prior to acquiring a pulse to
use to seed that analysis. The NIST Beacon manual refers to this as
‘committing upfront’ or a ‘commiting statement’. See section 7.2: “Ex
post facto-verifiable random sampling” in the [official reference
manual](https://doi.org/10.6028/NIST.IR.8213-draft)
</details>

#### Notes

1.  The reason it is ideal to pre-specify when you will acquire the seed
    is to prevent people from locally running their analyses every
    minute/day until they get a random pulse with a seed that works for
    their desired narrative and then selectively reporting that outcome.
2.  The hexsticker logo I am currently using is AI generated and is a
    placeholder while I work with a North Carolina based artist to
    create an original logo. To my knowledge there is no way for me to
    interrogate the provenance of reference images used by currently
    available commercial generative AI tools, and while I’ve made
    efforts to reverse image search it is possible that the final
    produced image is substantially similar to original work previously
    published on the internet. If you are an artist and believe this
    logo is plagiarizing your work, **please reach out** and I will take
    it down. Likewise for any art used to generate the flowchart diagram
    above; I am still thinking about the best way to publicly organize
    credit to icon artists whose work I’ve used. I expect to have a
    satisfactory solution by the first release (v0.1.0)
