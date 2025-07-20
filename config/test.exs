import Config

# Test environment configuration
# Keep logger level at debug for capture_log functionality but disable console output
config :logger, level: :debug

# Disable console output completely in tests to keep output clean
config :logger, :console, level: :emergency