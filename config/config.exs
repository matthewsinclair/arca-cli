# General application configuration
import Config

# Configure Arca.Cli
#
# Note: Configuration paths are now automatically derived by Arca.Config based on the application name.
# When not explicitly configured, Arca.Config will:
#   - Use ".app_name/" as the default config directory (e.g., ".arca_cli/")
#   - Use "config.json" as the default config filename
#   - These can be overridden with APP_NAME_CONFIG_PATH and APP_NAME_CONFIG_FILE environment variables
#     (e.g., ARCA_CLI_CONFIG_PATH and ARCA_CLI_CONFIG_FILE)
config :arca_cli,
  env: config_env(),
  name: "arca_cli",
  about: "📦 Arca CLI",
  description: "A declarative CLI for Elixir apps",
  version: "0.1.0",
  author: "hello@arca.io",
  url: "https://arca.io",
  prompt_symbol: "📦",
  debug_mode: false,
  configurators: [
    Arca.Cli.Configurator.DftConfigurator
  ]

# Configure Arca.Config to ensure it uses the right config domain
config :arca_config,
  config_domain: :arca_cli

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
