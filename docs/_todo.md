# FUTURE TESTING

5/1

- rewrite tests in test-api_get_seed so they pass and then I”M DONE with
  tests;; all are passing -\> github

- put pre-alpha version on github pages

  - remove \_todo’s from github repo
  - SITE
    - text color stuff
    - HOW TO INSTALL VIA GITHUB
      - test installation
    - toc for readme
    - github readme details
    - GITHUB
      - <https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax>
        - footnotes, anchor links
        - make sure my link to vignettes work
        - callouts

- write next steps

  - dev mode: no verifying of pulses, etc

- continue cleaning up repo

- fix any tests that fail due to message ordering changing due to
  skiplist stuff

- test that now having added verify_historical_seed to the verify_log
  none of my tests are breaking

  - this may require new vcrs due to skiplist, however none of my pulses
    are \> a few days ago, and VCR will make it seem like the most
    recent pulse is on the same day /minute as the stored pulse so….
    \#!\_RETURN

- check that removing the default arg for .to_raw didn’t break anything
  (regression tests)

- test that the pulse_time thing works by making requests to read from
  log very close to time you wrote to log

- PKGDOWN PKGDOWN PKGDOWN \# PKGDOWN TODO

- preregistration ex:

  - xyz is related to abc what’s my criterion for hypothesis? LU
  - 
  - hypothesis: regardless of seed, when i randomly sample 50k poitns
    the estimate will be within 0.1 of pi. do this 100 times, show 99%
    empirical CI
  - 

- readme page: adapt from DESCRIPTION

  - how to pronounce
  - how where the image comes from (beaker-\> swirling toget)

- example usage pages

  - figure out how to ‘order’ the reference materials:
    - PUBLIC functions first

    - INTERFACE FOR BEACON 3D5A80 F9F5FF; 8895b3

    - then private functions (anythign starting with ‘.’)
  - fix the syntax highlighitng for R6 classes so the css aligns and has
    same colors as normal function man pages
  - in vignettes
  - MAKING VIGNETTES:
    - all =’s go to \<-’s
    - figure out footnotes
    - figure out tabsets
    - figure out floating/docked table of contents
      <https://pkgdown.r-lib.org/articles/test/rendering.html>

- get avatar on the site

- Documentation \#’ @keywords internal

- put on my personal website a ‘packages’ folder and figure out how to
  link it to that

  - beacr icon on th

- coding syntax highlighting stuff

- spell check on everything in documentation and pkgdown

- change to give up on the timestamp thing and only call pulse indices

- finish verbosity/etc settings

- LOWchange defaults for log files to workspace (warning re: long debug
  log–purge and reset? frequency in cli/rlang?)

- make decision on how to handle precommitment/prereg optional and
  strict modes.. (curently getoption strict for reading log when no
  precommit available)

  - argument to inform that is “alwasy show to user” and then it orutes
    to cli_message not rlang::inform and hopefully gets shown even if
    global log level is set to error (i.e. muffling info, warning, etc)

- keep in mind I want fully reproducible option so some option to auto
  yes to the prompts is required for CI

- change ‘precommitment’ everywhere to ‘preregistration’ except where
  explicitly talking about NIST precommitment value

- MAYBE DELAY THIS; move communal code from interface to BeaconGeneric,
  in docs only put in the interface what ppl need to implement to use
  get_seed and etc

- FIGURE OUT IF I NEED VGLUE ON THE COND CONSTRUCTOR AS WELL AS ON THE
  ACTUAL RLANG THROW O RJUST ON THE RLANG THROW (need tests to see if
  one causes an error or not)

- WRITE TESTS FOR MY LOGGING so I don’t have any hidden regressions

- FUTURE: integrate easy way to set up a github action or codespace so
  that 1) automatically runs the code on a future pulse (i.e. using
  targets to orchestrate mulitiple steps) or ppl can verify themselves
  on a compatible environment in the future

- before trying to fix the cli stuff w/ logger: roll back to using only
  rlang (the cli:: calls at the bottom of funcs like .success, etc need
  to be changed back to rlang::inform…) and see if it’s not too hard to
  ergonomically interpolate stuff there.. JUST USE SPRINTF OR ADD GLUE
  AS A DEPENDENCY AND USE RLANG NORMALLY
  rlang::inform(glue::glue(“this{a}”)) e.g. (OR w/ my functions:)
  .success(glue::glue(‘this {a}’)) THIS WORKS PERFECTLY FINE THANK FUCK

- return to fix logging. What i want:

  - some way to 1) easily interpolate to make logging in-place very
    ergonomic
  - 2.  make log levels easily turnable on / off
  - 3.  make error throwing and logging in the same call I MAY NEED TO:
  - just do a ‘log mode’ where everything gets redirected via sink()
    instead of dealing with this bullshit of cli::glue stuff being abel
    to be printed but not logged via logger

- verify_claim() public api function that can be called on a ts/randout
  or a full log file, then call this in my get_seed() when reading from
  log

- do NOT deal with timestamps even when validating pulses; rewrite the
  logic for the pulse_from_tiemstamp and make it look for the latest
  pulse, if the current is \> then return the latest pulse (t should
  already do this…anyway I had a flaky test issue where a pulse gave a
  404 error)

- test the base cases for get_seed and reset seed

  - new seed from scratch, passing a prereg val: checks that value
    (downloads, hashes etc)
  - new seed from reading, etc “”

- test w/ user passed file SPECIFICALLY passing a file path that is
  LOCAL i.e. in the proj dir so that users can have transparent logs not
  have it stored on the file system somewher

  - FUTURE: use rprojroot to make it auto go in local workspace?? IN
    GET_SEED when reading from log: \#! \_RETURN announce when verifying
    from URL that 1) the registration was published before the pulse
    timestamp and 2) the hash of the registration matches the hash when
    you download the file

- write functio to CHECK THE HASH (i.e. get download url, req to
  downlaod (menu to let them know tthe size and let them choose to do in
  a tmp folder, withr) then hash and confirm no change)

- check if beacr name is available

- put out alpha version

  - new git branch for ‘release’ (etc may have to make a whole new repo
    if I want ‘main’ to be the release brnach, etc)
  - documentation cleaned up
  - pkgdown set up
  - uses beacon image from gpt as icon
  - bare min: readme.Rmd showing examples.
  - slightly more:
    - !examples! vignettes
      - very simple; generate, save seed to file, reload seed from file
      - example: use the link to your public pre-commitment to your
        analysis//hypothesis and it will concat them together for you
        - need to write companion function to un-concat these together
          // verify that the seed was requested at xyz timestamp
          - save the timestamp of the gen call in the file so its very
            easy to validate; just read that file and call ‘verify’ at
            the end of the script even, and it will work for you when
            you first run and also for ppl reproducing
        - warning in that function that your precommitment should have
          the timestamp that you will be runing the analysis on (or at
          least )
  - IF TIME contibution guidelines, explaint he interface thing, line
    notes
  - if time, github issues/project managemnet for next stages
  - (NOT REQUIRED FOR V1):news log (LU how ppl do it in R, otherwise
    just use scriv)

CURRENT BIG PICTURE: - get one single fresh seed; bare min. - Check that
it is correct (matches last precommit, timing from last one works, prev
value matches prev pulse’s value) - FUTURE: check dubious: where prev
value matches prev pulse’s value but the precommit doesn’t - LATER: if
pulse is same as last, what do? - LATER: handle if gap//delay

- verify that a seed generated on a date/time is correct
  - pass timestamp/datetime and provide all timestamps (nested list
    hour/min)
  - FUTURE: (skiplist)

POLISHING: - \#!\_RETURN \#\_HIPRIO add the inform_spaced to all msgs
(not just inform but error, etc) and make sure the new cli inform and
log still works with interpolation of glue shit - ! \#!\_RETURN
\#\_HIPRIO make sure to test the num_skips and ensure there isn’t any
bugs with the progressbar - delete vcr and rerun all tests keeping only
those I need - comment wrap everything - demo diagram of this
prereg/pulse acquisition thing - article on ‘verify_historical_seed’ and
why needed - all \_RETURNs - formalize the documentation style: name,
then returns, then params, then examples, then else - source lnks aon
all pkgdown articles - <https://github.com/helske/changer> - replace
-61s w/ lubridate minutes(1) - all \_LINENOTEs - all numbering is same
(1. vs 1)) - turn all \<- into = except for functions - all
sprintf/paste0etc to glue

TESTS: - putting in systime not converted to milliseconds should return
value of 2018 etc - <https://books.ropensci.org/http-testing/>

BIG PICTURE FUTURE: - have this easily register a github action to RUN A
PIPELINE in the future after pre-committing to a statement - make it
easy to snapshot states of the chain to make sure there are distributed
copies (rewriting history can only happen if the only way to read the
chain is by api calls from one server that can rewrite all subsequent
calls) - I should then give opiton to compare local copy//online mirror
to the current API to see if there is any divergence

FUTURE little stuff - function to check WHEN the deviation from the
chain happened (i.e. when the skiplist verification fails)

COPY - .func for helper, camel case for anythign that’s camelcase in the
API (inconsistently used), UpperCamel for R6, etc. UpperCamel for error
classes

5/2 - rlang abort/message/etc get to know - change nzchar stuff to
identical(var,““) -\> helper - warn re: the ‘this pkgdoesn’t do
validation of xyz’ set frequency to periodic/once - set freq id, then in
’reset defaults func (future) call that freq id to reset l - set package
default/global options a descriptor of all error messages - prefix error
messages with package name

LOGGING - logger -\> rlang appender w/ appender tee. global
settings/onload for log file for the appender_tee - in teh custom
appender; log each msg, then log warn/abort/etc, then if global
threshold above threshold for throwing, throw that error/warning. - use
rlang condition formatting for check marks etc

- check first for setting for logger appender type; set default to be
  log file in the data_dir for this pkg and set default setting to be
  debug.
  - test enabling 1) changing to an in-workspace log file and 2)
    changing to console
- \#! \_RETURN change default log appener to file

rlang errors; - body w/ c() -
<https://rlang.r-lib.org/reference/topic-error-call.html> for making
errors more user friendly by bubbling up to cllaer env \# portfolio -
simple package for queueing messages and handling easy replay of
messages when you want - usethis:: cucumber - positron cucumber
intellisense for r (scenarios) - testthat capture all conditions from a
function call not just the messages or the first one, etc \# BUGS

- test backwards pulses; I beleive this is not currently erroring

- requires testing the newly implemented feature where I can put in
  pulse/chainindex to get_seed to get spec pulse/chain index -! This
  likely has bugs where i’ve hard coded checking timestamps relative to
  current time but I actually need to be checkign timestamps relative to
  the pulse time?

- in verify skiplist for over a year back; presents the duration as 558
  days and 558 pulses not as 1year x months x days. It only performs
  about 20ish queries..

- EXPLICITLY error/decline to
  beacon$`hash anything that isn't either a hexstring or raw; then MAKE SURE that the precommitment thing works (get the i-1 thing passing if it isn't)
    - FIRST check that beacon`$hash checks that the thing it is hashing
  is hexstring before hashing it (i.e. NO hashing a raw essage)

- test num of API calls for a skiplist made equals roughly the estimated
  amount

# FUTURE

- extend log utils: pass condition to .error and it will error w/ that
  message and class only if that condition is false
- cyclic log//snapshot log run
- prepend to msgs when strictness is altered that that’s why this msg is
  an error not a warning, etc
- ex of seed hacking referenced to in readme
- vignette on ‘what’s hash-chaining?’ linked to in readme
- LU <https://docs.twine.world/twine-protocol-documentation>
- handlers\[\[1L\]\] issue w/ logging which fucntion a msg was sent in
- recording multiple pulses in seed_log
- confirm before resetting log, giving optiont o fileshow it
- prompt then re-enter on not finding valid osf id
- read openssl’s :::hex_to_raw helper and see if I should be using that
  instead of my function
- allow passing ina seed and timestamp etc and verify historical like
  that not just via seed log
- using cli progress steps for cleaner progress reports
- speed up skiplist?
- FIX LOGGING to use single .signal function
- fix cli progress stuff, add spinners, time elapsed messages, etc
- add api rate limiting for skip lists
- future: fix progressbar for skiplist to be more ergonomic
- fuutre: onboarding tutorial to demo/explain what pulse chains are etc
  and hlep them understand what the msgs I am sending via .inform are
  doing
- next version: option to skip verification for
  experimentation//development mode and then change that feature before
  posting code
- contribution guidelines (low prio)
  - style; use = but can convert
  - .internals etc
  - file naming structure
  - describe / it for tests
- a way to ensure that if any error occurred in the get_seed process no
  long was written/overwrittne during
- currently doesn’t do skiplist verification when first acquiring pulse
  only every time thereafter using (reading from log)
- make sure that if ANY pulses in the chain error then it errors early;
  verify with a test
- make sure resetting seed log deletes .json not .log files
- make an api function to update the curr hash library in pkg
  settings.json
- \#!\_RETURN \_HIPRIO test \$validate_pulse spec if the pulse rnadlocal
  is compromised (requires me to hash the rest of the message and update
  randoutput to match)
  - \#!\_RETURN add ‘hashing messge and confirming that randout is the
    hash of the whole message’ as an internal validity check for
    NISTBeacon \#=======================================
