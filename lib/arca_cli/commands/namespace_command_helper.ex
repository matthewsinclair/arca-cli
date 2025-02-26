defmodule Arca.CLI.Commands.NamespaceCommandHelper do
  @moduledoc """
  Provides helper macros to simplify creating namespaced (dot notation) commands.
  
  ## Usage Example
  
  ```elixir
  defmodule MyApp.CLI.Commands.Dev do
    use Arca.CLI.Commands.NamespaceCommandHelper
    
    namespace_command :info, "Display development environment information" do
      \"\"\"
      Development Environment Information:
      Mix Environment: #{Mix.env()}
      Project Name: #{Mix.Project.config()[:app]}
      Project Version: #{Mix.Project.config()[:version]}
      \"\"\"
    end
    
    namespace_command :deps, "List project dependencies" do
      deps = Mix.Project.config()[:deps]
      |> Enum.map(fn 
        {app, _} -> to_string(app)
        {app, _, _} -> to_string(app)
      end)
      |> Enum.join("\n")
      
      "Dependencies:\n" <> deps
    end
  end
  ```
  
  This will generate:
  - `DevInfoCommand` module with command name `dev.info`
  - `DevDepsCommand` module with command name `dev.deps`
  """
  
  @doc """
  Main macro for use statements that sets up the namespace from the module name.
  
  Extracts the namespace from the last part of the module name:
  - `MyApp.CLI.Commands.Dev` becomes namespace `dev`
  - `MyApp.CLI.Commands.System` becomes namespace `system`
  """
  defmacro __using__(_opts) do
    quote do
      import Arca.CLI.Commands.NamespaceCommandHelper, only: [namespace_command: 3]
      
      @namespace __MODULE__
                |> Module.split()
                |> List.last()
                |> String.downcase()
      
      # Make the namespace available to other macros
      Module.register_attribute(__MODULE__, :namespace, accumulate: false)
      @namespace @namespace
    end
  end
  
  @doc """
  Generates a new command module in the current namespace.
  
  ## Parameters
  
  - `name`: The name of the command (without namespace)
  - `description`: The command description for help text
  - `do_block`: The code block that will be executed when the command runs
  
  ## Example
  
  ```elixir
  namespace_command :info, "Display info" do
    "Some information: " <> inspect(System.version())
  end
  ```
  """
  defmacro namespace_command(name, description, do_block) do
    quote do
      namespace = @namespace
      command_name = :"#{namespace}.#{unquote(name)}"
      
      # Generate the command module
      module_name = Module.concat([
        Arca.CLI.Commands,
        "#{String.capitalize(namespace)}#{String.capitalize(to_string(unquote(name)))}Command"
      ])
      
      defmodule module_name do
        @moduledoc """
        Namespaced command: #{command_name}
        
        #{unquote(description)}
        """
        use Arca.CLI.Command.BaseCommand
        
        config command_name,
          name: to_string(command_name),
          about: unquote(description)
        
        @impl Arca.CLI.Command.CommandBehaviour
        def handle(_args, _settings, _optimus) do
          unquote(do_block)
        end
      end
    end
  end
end