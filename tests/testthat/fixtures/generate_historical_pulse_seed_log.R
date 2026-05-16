# Reset seed log if already present
log_file_path = test_path("fixtures", "historical_pulse_seed_log.json")
if (fs::file_exists(log_file_path)) {
  fs::file_delete(log_file_path)
}

# Write new seed log
beacr::get_seed(
  log_file = log_file_path,
  chain_index = 2,
  pulse_index = 100
)

#======================================= TAMPERED LOG

tampered_historical_log_file_path = test_path(
  "fixtures",
  "tampered_historical_pulse_seed_log.json"
)


if (fs::file_exists(tampered_historical_log_file_path)) {
  fs::file_delete(tampered_historical_log_file_path)
}

# Write new seed log
beacr::get_seed(
  log_file = tampered_historical_log_file_path,
  chain_index = 2,
  pulse_index = 100
)

# Read back in the logged file
log_ = jsonlite::read_json(tampered_historical_log_file_path)

log_$output_with_preregistration = .change_byte(
  log_$output_with_preregistration
)

jsonlite::write_json(
  log_,
  tampered_historical_log_file_path,
  auto_unbox = TRUE,
  pretty = TRUE,
  null = "null"
)
