#!/usr/bin/env elixir

# Generate arca command completions for rlwrap
# This script generates a completion file for rlwrap based on the commands available in Arca CLI

Mix.install([
  {:arca_cli, path: "../.."} # Load the arca_cli from our parent directory
])

defmodule CompletionGenerator do
  def main do
    # Get all available commands
    commands = Arca.CLI.commands()
    |> Enum.map(fn module ->
      {cmd_atom, _opts} = apply(module, :config, []) |> List.first()
      Atom.to_string(cmd_atom)
    end)
    |> Enum.sort()

    # Create common commands and additional keywords
    common_commands = ["help", "quit", "q!", "?", "tab"]
    all_completions = (commands ++ common_commands) |> Enum.uniq() |> Enum.sort()

    # Write to completion file
    completion_file = Path.join([File.cwd!(), "scripts", "completions", "arca_completions"])
    File.write!(completion_file, Enum.join(all_completions, "\n"))
    File.chmod!(completion_file, 0o644)

    IO.puts("Generated completions file at #{completion_file}")
    IO.puts("Total commands: #{length(all_completions)}")
  end
end

CompletionGenerator.main()