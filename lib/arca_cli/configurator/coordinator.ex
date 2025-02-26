defmodule Arca.CLI.Configurator.Coordinator do
  @moduledoc """
  The `Arca.CLI.Configurator.Coordinator` is responsible for coordinating all of the configuration necessary to get an Arca.CLI up and running.
  """

  alias Arca.CLI.Configurator.DftConfigurator
  require Logger

  @doc """
  Coordinate setup of the CLI. If no configuration type is passed in, default to `Arca.CLI.Configurator.DftConfigurator`.
  Accepts either a single module or a list of modules that implement the `Arca.CLI.Configurator.ConfiguratorBehaviour` protocol.
  """
  def setup(cfg8r \\ DftConfigurator)

  def setup(cfg8r) when is_atom(cfg8r) do
    cfg8r.setup()
  end

  def setup(cfg8r_list) when is_list(cfg8r_list) do
    {unique_cfg8rs, duplicate_cfg8rs} =
      cfg8r_list
      |> Enum.group_by(& &1)
      |> Enum.split_with(fn {_key, value} -> length(value) == 1 end)

    if duplicate_cfg8rs != [] do
      duplicated_modules = duplicate_cfg8rs |> Enum.map(fn {key, _value} -> key end)
      Logger.warning("Duplicate configurators found and rejected: #{inspect(duplicated_modules)}")
    end

    unique_cfg8r_list = unique_cfg8rs |> Enum.map(fn {key, _value} -> key end)

    {combined_config, subcommand_names} =
      Enum.reduce(unique_cfg8r_list, {%{}, %{}}, fn cfg8r, {acc, name_acc} ->
        cfg8r_config = cfg8r.create_base_config() |> Enum.into(%{})
        cfg8r_commands = cfg8r.commands()

        merged_config =
          Map.merge(acc, cfg8r_config, fn _key, v1, v2 ->
            case {v1, v2} do
              {list1, list2} when is_list(list1) and is_list(list2) -> list1 ++ list2
              {_, v2} -> v2
            end
          end)

        updated_names =
          Enum.reduce(cfg8r_commands, name_acc, fn cmd, acc ->
            [{cmd_name, _}] = cmd.config()
            Map.update(acc, cmd_name, [cfg8r], &[cfg8r | &1])
          end)

        {merged_config, updated_names}
      end)

    duplicated_commands = Enum.filter(subcommand_names, fn {_cmd, cfgs} -> length(cfgs) > 1 end)

    if duplicated_commands != [] do
      Logger.warning(
        "Duplicate subcommand names found in the following configurators: #{inspect(duplicated_commands)}"
      )
    end

    final_config =
      inject_subcommands(combined_config, Enum.flat_map(unique_cfg8r_list, & &1.commands()))

    final_config = Enum.into(final_config, [])
    Optimus.new!(final_config)
  end

  defp inject_subcommands(config, commands) do
    processed_commands = Enum.map(commands, &get_command_config/1)

    Map.update(config, :subcommands, [], fn subcommands ->
      merge_subcommands(subcommands, processed_commands)
    end)
  end

  defp merge_subcommands(existing, new) do
    Keyword.merge(existing, new, fn _key, _val1, val2 -> val2 end)
  end

  defp get_command_config(command_module) do
    # Get command configuration and preserve any custom options
    # (like hidden: true) that were specified in the command config
    [{cmd, config}] = command_module.config()
    {cmd, config}
  end
end
