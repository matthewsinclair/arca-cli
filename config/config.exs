# General application configuration
import Config

# Configure Arca.CLI
config :arca_cli,
  env: config_env(),
  default_config_path: "~/.arca/",
  default_config_file: "config.json",
  config_path: System.get_env("ARCA_CONFIG_PATH", "~/.arca/"),
  config_file: System.get_env("ARCA_CONFIG_FILE", "config.json"),
  name: "arca_cli",
  about: "📦 Arca CLI",
  description: "A declarative CLI for Elixir apps",
  version: "0.1.0",
  author: "hello@arca.io",
  url: "https://arca.io",
  prompt_symbol: "📦",
  configurators: [
    Arca.CLI.Configurator.DftConfigurator
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
