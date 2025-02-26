defmodule Arca.CLI.Utils do
  use OK.Pipe
  require Jason

  @doc """
  Forms a URL-encoded string from the given parameters.

  ## Parameters
  - `params`: A map of key-value pairs to be URL-encoded.

  ## Returns
  - A string in the format "key1=value1&key2=value2".

  ## Examples
      iex> Arca.CLI.Utils.form_encoded_body(%{"key1" => "value1", "key2" => "value2"})
      "key1=value1&key2=value2"
  """
  def form_encoded_body(params) do
    params
    |> Enum.map(fn {key, value} -> key <> "=" <> value end)
    |> Enum.join("&")
  end

  @doc """
  Parses the JSON body from the given response map.

  ## Parameters
  - `response`: A map containing the response, with the JSON body under the `:body` key.

  ## Returns
  - `{:ok, decoded_body}` if the JSON body was successfully decoded.
  - `{:error, reason}` if an error occurred during decoding.

  ## Examples
      iex> response = %{body: ~s({"key": "value"})}
      iex> Arca.CLI.Utils.parse_json_body(response)
      {:ok, %{key: "value"}}
  """
  def parse_json_body(response) do
    response
    |> Map.fetch(:body)
    ~>> Jason.decode(%{keys: :atoms})
  end

  @doc """
  Wraps the given value in an `{:ok, value}` tuple.

  ## Parameters
  - `x`: The value to be wrapped.

  ## Returns
  - `{:ok, x}`.

  ## Examples
      iex> Arca.CLI.Utils.return("value")
      {:ok, "value"}
  """
  def return(x) do
    {:ok, x}
  end

  @doc """
  Returns the value if it's an `{:ok, value}` tuple, or a default value if it's an error tuple.

  ## Parameters
  - `x`: The result tuple (`{:ok, value}` or `{:error, reason}`).
  - `default`: The default value to return in case of an error.

  ## Returns
  - The value from the `{:ok, value}` tuple.
  - The default value if `x` is an `{:error, reason}` tuple.
  - The original value if `x` is neither.

  ## Examples
      iex> Arca.CLI.Utils.with_default({:ok, "value"}, "default")
      "value"

      iex> Arca.CLI.Utils.with_default({:error, "error"}, "default")
      "default"
  """
  def with_default(x, default) do
    case x do
      {:ok, ok} -> ok
      {:error, _} -> default
      _ -> x
    end
  end

  @doc """
  Converts the given URL into an ANSI-formatted clickable link.

  ## Parameters
  - `url`: The URL to be converted.

  ## Returns
  - A string containing the ANSI-formatted clickable link.

  ## Examples
      iex> Arca.CLI.Utils.to_url_link("http://example.com")
      "\e[96m\e[4m\e]8;;http://example.com\ahttp://example.com\e]8;;\a\e[0m"
  """
  def to_url_link(url) do
    "#{IO.ANSI.light_cyan()}#{IO.ANSI.underline()}\e]8;;#{url}\a#{url}\e]8;;\a#{IO.ANSI.reset()}"
  end

  @doc """
  Prints the given output, filtering out blank lines before printing.

  ## Parameters
  - `out`: The output to be printed.

  ## Returns
  - :ok

  ## Examples
      iex> Arca.CLI.Utils.print(["Line 1", "", "Line 2", ""])
      [:ok, :ok, :ok]
  """
  def print(out) do
    out |> filter_blank_lines |> put_lines
  end

  @doc """
  Prints an ANSI-formatted version of the given map.

  ## Parameters
  - `to_print`: The map to be printed.

  ## Returns
  - :ok

  ## Examples
      iex> Arca.CLI.Utils.print_ansi(%{key: "value"})
      :ok
  """
  def print_ansi(to_print) when is_map(to_print) do
    to_print |> to_str |> print_ansi
  end

  def print_ansi(to_print) when is_nil(to_print) do
    "nil" |> print_ansi
  end

  def print_ansi(to_print) when is_atom(to_print) do
    to_print |> to_str |> print_ansi
  end

  def print_ansi(to_print) when is_tuple(to_print) do
    to_print |> to_str |> print_ansi
  end

  def print_ansi(to_print) do
    to_print |> IO.ANSI.format() |> IO.puts()
  end

  @doc """
  Prints a pretty-printed version of the given term.

  ## Parameters
  - `term`: The term to be printed.

  ## Returns
  - :ok

  ## Examples
      iex> Arca.CLI.Utils.pretty_print(%{key: "value"})
      :ok
  """
  def pretty_print(term) do
    IO.puts(to_str(term))
  end

  @doc """
  Prints each line from the given list.

  ## Parameters
  - `lines`: A list of lines to be printed.

  ## Returns
  - :ok

  ## Examples
      iex> Arca.CLI.Utils.put_lines(["Line 1", "Line 2"])
      [:ok, :ok]
  """
  def put_lines(lines) when is_list(lines) do
    Enum.map(lines, &print_ansi/1)
  end

  def put_lines(map) when is_map(map) do
    map |> IO.inspect()
  end

  def put_lines(tpl) when is_tuple(tpl) do
    tpl |> IO.inspect()
  end

  def put_lines(string) when is_binary(string) do
    string |> String.trim() |> print_ansi
  end

  def put_lines(isnil) when is_nil(isnil) do
    "nil" |> print_ansi
  end

  def put_lines(isatom) when is_atom(isatom) do
    unless isatom == :ok, do: to_string(isatom) |> print_ansi
  end

  @doc """
  Converts the given term to a string with pretty printing enabled.

  ## Parameters
  - `term`: The term to be converted.

  ## Returns
  - A string representation of the term.

  ## Examples
      iex> Arca.CLI.Utils.to_str(%{key: "value"})
      "%{key: \\"value\\"}"
  """
  def to_str(term) when is_atom(term) do
    inspect(term, pretty: true, limit: :infinity)
  end

  def to_str(term) when is_boolean(term) do
    inspect(term, pretty: true, limit: :infinity)
  end

  def to_str(term) when is_function(term) do
    inspect(term, pretty: true, limit: :infinity)
  end

  def to_str(term) when is_list(term) do
    inspect(term, pretty: true, limit: :infinity)
  end

  def to_str(term) when is_map(term) do
    inspect(term, pretty: true, limit: :infinity)
  end

  def to_str(term) when is_nil(term) do
    inspect(term, pretty: true, limit: :infinity)
  end

  def to_str(term) when is_pid(term) do
    inspect(term, pretty: true, limit: :infinity)
  end

  def to_str(term) when is_port(term) do
    inspect(term, pretty: true, limit: :infinity)
  end

  def to_str(term) when is_reference(term) do
    inspect(term, pretty: true, limit: :infinity)
  end

  def to_str(term) when is_tuple(term) do
    inspect(term, pretty: true, limit: :infinity)
  end

  def to_str(term) when is_binary(term) do
    inspect(term, pretty: true, limit: :infinity)
  end

  def to_str(term) when is_bitstring(term) do
    inspect(term, pretty: true, limit: :infinity)
  end

  def to_str(term) when is_integer(term) do
    inspect(term, pretty: true, limit: :infinity)
  end

  def to_str(term) when is_float(term) do
    inspect(term, pretty: true, limit: :infinity)
  end

  def to_str(term) when is_number(term) do
    inspect(term, pretty: true, limit: :infinity)
  end

  @doc """
  Determines the type of the given term.

  ## Parameters
  - `term`: The term whose type is to be determined.

  ## Returns
  - The type of the term as an atom.

  ## Examples
      iex> Arca.CLI.Utils.type_of(:atom)
      :atom

      iex> Arca.CLI.Utils.type_of(true)
      :boolean

      iex> Arca.CLI.Utils.type_of(false)
      :boolean

      iex> Arca.CLI.Utils.type_of(fn -> dbg() end)
      :function

      iex> Arca.CLI.Utils.type_of([1, 2, 3])
      :list

      iex> Arca.CLI.Utils.type_of(%{ a: 1, b: 2 })
      :map

      iex> Arca.CLI.Utils.type_of(nil)
      :nil

      iex> Arca.CLI.Utils.type_of(self())
      :pid

      iex> p = Port.open({:spawn, "ls"}, [:binary])
      iex> Arca.CLI.Utils.type_of(p)
      :port

      iex> ref = make_ref()
      iex> Arca.CLI.Utils.type_of(ref)
      :reference

      iex> Arca.CLI.Utils.type_of({ 1, 2 })
      :tuple

      iex> Arca.CLI.Utils.type_of("a binary")
      :binary

      iex> Arca.CLI.Utils.type_of(<<1::1, 0::1, 1::1>>)
      :bitstring

      iex> Arca.CLI.Utils.type_of(42)
      :integer

      iex> Arca.CLI.Utils.type_of(42.42)
      :float
  """
  def type_of(term) when is_boolean(term), do: :boolean
  def type_of(term) when is_nil(term), do: nil
  def type_of(term) when is_atom(term), do: :atom
  def type_of(term) when is_function(term), do: :function
  def type_of(term) when is_list(term), do: :list
  def type_of(term) when is_map(term), do: :map
  def type_of(term) when is_pid(term), do: :pid
  def type_of(term) when is_port(term), do: :port
  def type_of(term) when is_reference(term), do: :reference
  def type_of(term) when is_tuple(term), do: :tuple
  def type_of(term) when is_binary(term), do: :binary
  def type_of(term) when is_bitstring(term), do: :bitstring
  def type_of(term) when is_integer(term), do: :integer
  def type_of(term) when is_float(term), do: :float
  def type_of(term) when is_number(term), do: :number
  def type_of(_term), do: :error

  @doc """
  Checks if the given data is blank.

  A blank value is:
  - `nil`
  - An empty string (only spaces are considered empty)
  - An empty list
  - An empty tuple
  - An empty map

  ## Parameters
  - `data`: The data to be checked.

  ## Returns
  - `true` if the data is blank.
  - `false` otherwise.

  ## Examples
      iex> Arca.CLI.Utils.is_blank?(nil)
      true

      iex> Arca.CLI.Utils.is_blank?("")
      true

      iex> Arca.CLI.Utils.is_blank?(["not blank"])
      false
  """
  def is_blank?(data) when is_binary(data), do: data |> String.trim() |> String.length() == 0
  def is_blank?(list) when is_list(list), do: length(list) == 0
  def is_blank?(tuple) when is_tuple(tuple), do: tuple_size(tuple) == 0
  def is_blank?(map) when is_map(map), do: map_size(map) == 0
  def is_blank?(nil), do: true
  def is_blank?(_), do: false

  @doc """
  Removes blank lines from the end of a list or string.

  Blank lines at the end of the list or string are removed, while blank lines in the middle are left intact.

  ## Parameters
  - `lines`: The list, tuple, string, map, atom, or other data type to be filtered.

  ## Returns
  - The filtered list, tuple, or string.
  - For other data types, returns the original value.

  ## Examples
      iex> Arca.CLI.Utils.filter_blank_lines(["Line 1", "Line 2", "", ""])
      ["Line 1", "Line 2"]

      iex> Arca.CLI.Utils.filter_blank_lines("Line 1\\nLine 2\\n\\n")
      "Line 1\\nLine 2\\n"
      
      iex> Arca.CLI.Utils.filter_blank_lines(123)
      123
  """
  def filter_blank_lines(lines)

  def filter_blank_lines(lines) when is_list(lines) do
    lines |> Enum.reverse() |> Enum.drop_while(fn line -> is_blank?(line) end) |> Enum.reverse()
  end

  def filter_blank_lines(lines) when is_tuple(lines) do
    lines |> Tuple.to_list() |> filter_blank_lines |> List.to_tuple()
  end

  def filter_blank_lines(map) when is_map(map), do: map

  def filter_blank_lines(atom) when is_atom(atom), do: atom

  def filter_blank_lines(number) when is_number(number), do: number

  def filter_blank_lines(boolean) when is_boolean(boolean), do: boolean

  def filter_blank_lines(string) when is_binary(string) do
    newstr = String.replace(string, ~r/\n\n$/, "\n")

    case newstr == string do
      true -> newstr
      false -> filter_blank_lines(newstr)
    end
  end

  # Catch-all clause for any other data type
  def filter_blank_lines(other), do: other

  @doc """
  Measures the execution time of a given function and returns a tuple with the duration in seconds and the function's result.

  ## Examples

      iex> {duration, result} = timer(fn -> :timer.sleep(1000); "Done" end)
      iex> is_integer(duration) and duration >= 1
      true
      iex> result
      "Done"

  """
  def timer(func) do
    start_time = DateTime.utc_now()
    result = func.()
    end_time = DateTime.utc_now()
    duration = DateTime.diff(end_time, start_time)
    {duration, result}
  end

  @doc """
  Returns the current function's fully-qualified name as a string with an optional parameter appended to the end.

  ## Examples

      iex> defmodule MyModule1 do
      ...>   def my_function do
      ...>     this_fn_as_string()
      ...>   end
      ...> end
      iex> MyModule1.my_function()
      "Arca.CLI.Utils.Test.MyModule1.my_function/0"

      iex> defmodule MyModule2 do
      ...>   def my_function_with_param do
      ...>     this_fn_as_string("additional_info")
      ...>   end
      ...> end
      iex> MyModule2.my_function_with_param()
      "Arca.CLI.Utils.Test.MyModule2.my_function_with_param/0: additional_info"

  """
  defmacro this_fn_as_string(optional_param \\ nil) do
    quote do
      function_info = __ENV__.function
      function_name = elem(function_info, 0)
      function_arity = elem(function_info, 1)
      module_name = __MODULE__ |> Atom.to_string() |> String.replace("Elixir.", "")
      base_info = "#{module_name}.#{function_name}/#{function_arity}"

      case unquote(optional_param) do
        nil -> base_info
        param -> "#{base_info}: #{param}"
      end
    end
  end

  defmacro this_function_is_not_implemented(optional_msg \\ nil) do
    quote do
      function_info = __ENV__.function
      function_name = elem(function_info, 0)
      function_arity = elem(function_info, 1)
      opt_msg = if unquote(optional_msg), do: ": #{unquote(optional_msg)}", else: ""

      Logger.warning(
        "#{__MODULE__} has not implemented #{function_name}/#{function_arity}#{opt_msg}"
      )
    end
  end
end
