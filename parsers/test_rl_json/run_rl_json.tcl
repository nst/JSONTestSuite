package require rl_json
try {
  set s [read stdin]
  ::rl_json::json parse $s
} on error {e o} {
    exit 1
}
exit 0
