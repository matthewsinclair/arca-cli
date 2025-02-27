# General application configuration
import Config

# Configure Arca.Cli
#
# Note: Configuration paths are now automatically derived by Arca.Config based on the application name.
# When not explicitly configured, Arca.Config will:
#   - Use "~/.arca/" as the default config directory
#   - Create a config file named after the application (e.g., "arca_cli.json")
#   - These can be overridden with ARCA_CONFIG_PATH and ARCA_CONFIG_FILE environment variables
config :arca_cli,
  env: config_env(),
  name: "arca_cli",
  about: "📦 Arca CLI",
  description: "A declarative CLI for Elixir apps",
  version: "0.1.0",
  author: "hello@arca.io",
  url: "https://arca.io",
  prompt_symbol: "📦",
  configurators: [
    Arca.Cli.Configurator.DftConfigurator
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
