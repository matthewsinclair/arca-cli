import Config

# Configure logger based on runtime environment
if System.get_env("ARCA_REPL_MODE") == "true" && config_env() != :prod do
  # Ensure logs directory exists
  log_dir = ".arca/logs"
  File.mkdir_p!(log_dir)

  # Configure file backend for REPL/CLI mode
  config :logger,
    backends: [{LoggerFileBackend, :file_log}]

  config :logger, :file_log,
    path: Path.join(log_dir, "#{Date.utc_today()}.log"),
    level: :debug,
    format: "$time $metadata[$level] $message\n",
    metadata: [:request_id, :module, :function]
end
