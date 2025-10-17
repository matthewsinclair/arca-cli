import Config

# Configure logger based on runtime environment
if System.get_env("REPL_MODE") == "true" && config_env() != :prod do
  # Ensure logs directory exists
  log_dir = ".arca_cli/logs"
  File.mkdir_p!(log_dir)

  # Configure file backend for REPL/CLI mode
  # Note: Backend is added via LoggerBackends.add() in application start callback
  config :logger, :file_log,
    path: Path.join(log_dir, "#{Date.utc_today()}.log"),
    level: :debug,
    format: "$time $metadata[$level] $message\n",
    metadata: [:request_id, :module, :function]

  # Explicitly disable console backend
  config :logger, :console, level: :emergency
end
