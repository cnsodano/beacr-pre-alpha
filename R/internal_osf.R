# Internal logic powering the OSF preregistration verification feature

#'  Sanitize preregistration identifier strings and parse for OSF file IDs
#'
#' #_LINENOTE: 30dc17c26b90.md
.sanitize_url <- function(str_) {
  match = stringr::str_match(str_, "^(https://.*files/)([A-z0-9]+)/?(.*)$")
  if (any(is.na(match))) {
    return(str_)
  }
  prefix = match[2]
  id = match[3]
  postfix = match[4]
  if (postfix != "") {
    .error(
      "Detected that a url was passed with a postfix after the file id. In version 2 of the OSF API currently hashes are only exposed on the file id endpoint; perhaps you were looking for a specific version? Currently this package will only use the reported hash of the current version (and error if that is not version 1)"
    )
  }
  return(id)
}


.validate_is_osf <- function(str_) {
  #! _RETURN In future this will be useful for auto-converting to the
  #! correct input value in a factory function for the preregistration
  if (is.null(str_)) {
    .error("Invalid preregistration identifier (NULL)")
  }
  if (identical(str_, "")) {
    .error("Invalid preregistration identifier ('')")
  }
  .inform(
    c(
      "!" = "Validating the identifier passed to .get_preregistration_OSF() is not yet implemented; assuming the identifier to be a valid OSF URL or unique OSF file ID"
    ),
    class = "beacr.warning"
  )
  return(TRUE)
}

.make_OSF_request <- function(identifier) {
  file_id = .sanitize_url(identifier)
  baseurl = sprintf("https://api.osf.io/v2/files/%s/", file_id)
  resp <- httr2::request(baseurl) |>
    httr2::req_perform() |>
    httr2::resp_body_json()
  return(resp)
}

.get_preregistration_OSF <- function(identifier) {
  if (!.validate_is_osf(identifier)) {
    .inform(
      c(
        "!" = "In future versions, a warning will be emitted when passing an invalid identifier. For now, only unique file URIs in the form of `https://api.osf.io/v2/files/<FILE_ID>/` or simply `<FILE_ID>` is supported"
      ),
      class = "beacr.warning"
    )
  }
  resp = .make_OSF_request(identifier)
  .inform(
    c(
      "!" = "Currently this package doesn't check if the file provided is from a Registration. OSF Registrations do not have writable history (i.e. they cannot be changed after publication) providing an integrity guarantee whereas normal Projects do not. Please note that public preregistrations that do not have integrity guarantees are unsuitable for this kind of commitment scheme as the whole point is to ensure that you commit to using a future value in advance specifically in a way where you cannot change your commitment after that value is known."
    ),
    class = "beacr.warning"
  ) #!_RETURN; Not very familiar with OSF API but this is my understanding
  .stopifnot(
    #!_RETURN Not necessarily required, as any preregistration prior to the
    #! pulse is done without knowledge of the pulse
    resp$data$attributes$current_version,
    "because osf api v2 currently only exposes the hash of the current version of a file, files used as preregistrations must have current version 1"
  )
  timestamp_of_preregistration = lubridate::as_datetime(
    resp$data$attributes$date_created
  )
  if (timestamp_of_preregistration > Sys.time()) {
    # How did this even happen? Possible issue with user multiplying systime by
    # number greater than necessary in attempt to convert from seconds to
    # milliseconds (i.e. typo)
    .error(
      "error detected with osf's api: timestamp of the preregistration is listed as later than the current time."
    )
  }
  .validate_hash_osf(resp)

  return(list(
    hash = resp$data$attributes$extra$hashes$sha256,
    timestamp_of_preregistration = .timeStamp_to_unix_time(
      timestamp_of_preregistration
    ),
    preregistration_viewing_link = resp$data$links$html
  ))
}

.hash_preregistration_file <- function(file, preregistration_source) {
  switch(
    preregistration_source,
    "OSF" = {
      return(.hash_preregistration_file_osf(file))
    },
    {
      .error(
        "Not yet implemented: checking a file hash from a source other than OSF (Source provided: {preregistration_source}",
        class = "beacr.NotImplementedError"
      )
    }
  )
}

.hash_preregistration_file_osf <- openssl::sha256

.validate_hash_osf <- function(resp) {
  .inform(c(
    "i" = "Validating OSF file hash by downloading external preregistration file..."
  ))
  download_link_uri = resp$data$links$download
  # prompt here
  #! _return check where it gets downloaded to and alert where it was downloaded to (tmp dir?)
  choice = .prompt_menu(
    c(
      "Yes",
      "No, continue without verifying integrity of preregistration file"
    ),
    title = sprintf(
      "The preregistration file is %s MB in size. Download this file into memory to check the hash (verify file integrity)?",
      floor(resp$data$attributes$size / 10^6)
    )
  )
  switch(
    choice,
    "1" = {
      actual_file = httr2::request(download_link_uri) |>
        httr2::req_progress(type = "down") |>
        httr2::req_perform() |>
        httr2::resp_body_raw()
      hash_of_actual_file = .hash_preregistration_file_osf(actual_file)
      str_hash_of_actual_file = tolower(.raw_to_hex_str(hash_of_actual_file))
      .stopifnot(
        all(
          str_hash_of_actual_file == resp$data$attributes$extra$hashes$sha256
        ),
        "Hash of downloaded file does not match the hash reported by OSF. This suggests a breach in file integrity (e.g. file contents changed, or this package is out of date with current OSF hash practices (currently using openssl::sha256).\n Hash of downloaded file: {str_hash_of_actual_file}\n Posted of OSF file: {resp$data$attributes$extra$hashes$sha256} "
      ) #! _RETURN Make error msg programmatic, not hard coded. Relies on formalizing my validation interface probably
      .success(
        "Hash value reported by OSF's API matches the hash value of the actual file available for download from OSF"
      )
      invisible()
    },
    "2" = {
      .inform(c(
        "!" = "Continuing without manually verifying file integrity..."
      ))
      invisible()
    }
  )
  #!_LINENOTE: _RETURN still we are relying on OSF to not have tampered; they can still change BOTH the hash and the file on their server end...external database backups are necessary
}


# Returns list with hash, timestamp_of_preregistration,
# preregistration_viewing_link
.get_preregistration <- function(identifier, source = "OSF") {
  #! _RETURN In future will use .get_option() or manual arguments to specify
  #! what type of preregistration source you are using. Or, possibly use a
  #! R6 interface/implementers pattern like with BeaconInterface

  if (source == "OSF") {
    return(.get_preregistration_OSF(identifier = identifier))
  } else {
    .error(
      "Currently this package only supports using the OSF API as a preregistration source"
    ) #!_RETURN
  }
}
