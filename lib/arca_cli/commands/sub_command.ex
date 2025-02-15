defmodule Arca.CLI.Commands.SubCommand do
  @moduledoc """
  Use an `Arca.CLI.Commands.SubCommand` to quickly and easily build a new CLI sub-command. Sub commands are just like commands, but they can be nested within an existing CLI configuration. This allows for an outer commnand to work as a 'category' of commands, and for the nested commands to work just like an ordinary command.

  Note: this is just an example of what a sub-command looks like. In this case, the command "sub" takes one sub-coammd "one". To make your own sub-command, just use this as a template and add it to a Configurator like any other command.
  """
  import Arca.CLI.Utils
  use Arca.CLI.Command.BaseCommand
  use Arca.CLI.Command.BaseSubCommand

  config :sub,
    name: "sub",
    about: "Sub command",
    args: [
      cmd: [
        value_name: "CMD",
        help: "one | two | ...",
        required: true,
        parser: :string
      ],
      args: [
        value_name: "ARGS",
        help: "*",
        required: false,
        parser: :string
      ]
    ],
    sub_commands: [
      Arca.CLI.Commands.OneCommand
    ]
end

defmodule Arca.CLI.Commands.OneCommand do
  @moduledoc """
  Example sub-command for :sub.
  """
  use Arca.CLI.Command.BaseCommand
  import Arca.CLI.Utils

  config :one,
    name: "one",
    about: "Sub one.",
    args: [
      p1: [
        value_name: "p1",
        help: "Paramater One",
        required: false,
        parser: :string
      ]
    ]

  @doc """
  SuboneCommand
  """
  @impl Arca.CLI.Command.CommandBehaviour
  def handle(args, _settings, _optimus) do
    this_fn_as_string(args.p1)
  end
end
