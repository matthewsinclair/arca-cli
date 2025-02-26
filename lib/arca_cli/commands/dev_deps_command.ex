defmodule Arca.CLI.Commands.DevDepsCommand do
  @moduledoc """
  Command to display project dependencies.
  This is a namespaced command using dot notation (dev.deps).
  """
  use Arca.CLI.Command.BaseCommand

  config :"dev.deps",
    name: "dev.deps",
    about: "Display project dependencies."

  @impl Arca.CLI.Command.CommandBehaviour
  def handle(_args, _settings, _optimus) do
    deps = get_deps()
    header = "Project Dependencies:\n"
    
    deps_list = deps
    |> Enum.map(fn {app, version} -> "  #{app}: #{version}" end)
    |> Enum.join("\n")
    
    header <> deps_list
  end
  
  defp get_deps do
    Mix.Project.config()[:deps]
    |> Enum.map(fn 
      {app, requirement} when is_binary(requirement) -> {app, requirement}
      {app, opts} when is_list(opts) -> 
        version = Keyword.get(opts, :tag) || Keyword.get(opts, :branch) || Keyword.get(opts, :ref) || "latest"
        {app, version}
      {app, _version, opts} when is_list(opts) -> 
        version = Keyword.get(opts, :tag) || Keyword.get(opts, :branch) || Keyword.get(opts, :ref) || "latest"
        {app, version}
      {app, _version} -> {app, "latest"}
      app when is_atom(app) -> {app, "latest"}
    end)
    |> Enum.sort_by(fn {app, _} -> app end)
  end
end