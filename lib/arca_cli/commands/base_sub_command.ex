defmodule Arca.Cli.Command.BaseSubCommand do
  defmacro __using__(_) do
    quote do
      import Arca.Cli.Utils
      @behaviour Arca.Cli.Command.SubCommandBehaviour

      Module.register_attribute(__MODULE__, :sub_commands, accumulate: true)

      @before_compile Arca.Cli.Command.BaseSubCommand

      @doc """
      Command handler for the subcommand. Routes to the respective handler for the subcommands.
      """
      @impl Arca.Cli.Command.CommandBehaviour
      def handle(args, settings, _outer_optimus) do
        argv =
          args.args
          |> Map.values()
          |> Enum.filter(&(!is_nil(&1)))
          |> Enum.reverse()

        inner_optimus = subcommand_setup()

        Optimus.parse(inner_optimus, argv)
        |> handle_args(settings, inner_optimus)
        |> filter_blank_lines()

        # Note: no need to put lines here because that will happen via the original command
        # |> put_lines()
      end

      @doc """
      Handle the command line arguments for the sub command.
      """
      def handle_args({:ok, [subcmd], result}, settings, optimus) do
        handle_subcommand(subcmd, result.args, settings, optimus)
      end

      def handle_args({:error, reason}, settings, optimus) do
        handle_subcommand(:error, reason, settings, optimus)
      end

      def handle_args({:error, [cmd], [reason]}, settings, optimus) do
        handle_subcommand(:error, reason, settings, optimus)
      end

      @doc """
      Dispatch to the appropriate subcommand, if we can find one.
      """
      def handle_subcommand(cmd, args, settings, optimus) do
        case Arca.Cli.handler_for_command(cmd, sub_commands()) do
          nil ->
            Arca.Cli.handle_error([args])

          {:ok, _cmd_atom, handler} ->
            handler.handle(args, settings, optimus)
        end
      end

      @doc """
      Create a new Optimus config for the subcommands.
      """
      def subcommand_setup() do
        config()
        |> inject_subcommands()
        |> Optimus.new!()
      end

      @doc """
      Inject any subcommands into the provided Optimus config.
      """
      def inject_subcommands(optimus, commands \\ sub_commands()) do
        processed_commands = Enum.map(commands, &get_command_config/1)

        {top_level_keys, subcommands} =
          Keyword.split(optimus, [
            :name,
            :description,
            :version,
            :author,
            :allow_unknown_args,
            :parse_double_dash
          ])

        merged_subcommands = merge_subcommands(subcommands[:subcommands], processed_commands)

        top_level_keys ++ [subcommands: merged_subcommands]
      end

      defp merge_subcommands(existing, new) do
        existing = existing || []
        Keyword.merge(existing, new, fn _key, _val1, val2 -> val2 end)
      end

      defp get_command_config(command_module) do
        [{cmd, config}] = command_module.config()
        {cmd, config}
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @doc """
      Grab the list of (sub)commands that have been specified for this command.
      """
      def sub_commands() do
        [{cmd, config}] = __MODULE__.config()
        Keyword.get(config, :sub_commands, [])
      end
    end
  end
end
