# Support functions for CLI test cases
defmodule Arca.Cli.Test.Support do
  require Logger

  # Example config file
  @example_config_json_as_map %{
    "id" => "DOT_SLASH_DOT_LL_SLASH_CONFIG_DOT_JSON"
  }

  # Write a known config file to a known location
  def write_default_config_file(config_file, config_path) do
    config_file
    |> Path.expand(config_path)
    |> File.write(Jason.encode!(@example_config_json_as_map, pretty: true))
    |> case do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Ensures that the History GenServer is properly started for tests.
  This function can be called to guarantee History is available.
  """
  def ensure_history_started do
    if Process.whereis(Arca.Cli.History) == nil do
      # Logger.debug("Starting Arca.Cli.History for tests")
      case Arca.Cli.History.start_link() do
        {:ok, pid} -> {:ok, pid}
        {:error, {:already_started, pid}} -> {:ok, pid}
        error -> error
      end
    else
      {:ok, Process.whereis(Arca.Cli.History)}
    end
  end
end

# Ensure history is available for all tests
Arca.Cli.Test.Support.ensure_history_started()

ExUnit.start()
