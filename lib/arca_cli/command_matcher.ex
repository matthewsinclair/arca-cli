defmodule Arca.Cli.CommandMatcher do
  @moduledoc """
  Provides fuzzy command matching for the Arca CLI REPL.

  This module enables users to type partial commands that will be matched
  against the full command set. It supports:

  - Suffix matching: "engage" → "ll.agent.engage"
  - Partial namespace: "agent.create" → "ll.agent.create"
  - Abbreviations: "llm.conf" → "ll.llm.config"
  - Typo correction using edit distance

  ## Examples

      iex> CommandMatcher.fuzzy_match("engage", ["ll.agent.engage", "ll.agent.create"])
      {:single, "ll.agent.engage"}

      iex> CommandMatcher.fuzzy_match("agent", ["ll.agent.engage", "ll.agent.create", "ll.agent.list"])
      {:multiple, ["ll.agent.create", "ll.agent.engage", "ll.agent.list"]}

      iex> CommandMatcher.fuzzy_match("nonexistent", ["about", "help"])
      :no_match
  """

  @typedoc """
  Result of fuzzy matching attempt.
  """
  @type match_result ::
          {:single, String.t()}
          | {:multiple, [String.t()]}
          | :no_match

  @typedoc """
  Scoring result for a potential match.
  """
  @type score_result :: {String.t(), float()}

  @doc """
  Perform fuzzy matching on a command input against available commands.

  ## Parameters
    - input: The user's input command (potentially partial)
    - commands: List of all available command strings

  ## Returns
    - {:single, command} if exactly one command matches
    - {:multiple, commands} if multiple commands match
    - :no_match if no commands match
  """
  @spec fuzzy_match(String.t(), [String.t()]) :: match_result()
  def fuzzy_match(input, commands) do
    input = String.trim(input)

    # Handle empty input
    if input == "" do
      :no_match
    else
      # First check for exact match
      if input in commands do
        {:single, input}
      else
        # Try various matching strategies
        matches = find_matches(input, commands)

        case matches do
          [] -> :no_match
          [single] -> {:single, single}
          multiple -> {:multiple, Enum.sort(multiple)}
        end
      end
    end
  end

  @doc """
  Find all commands that could match the given input.

  ## Parameters
    - input: The user's input command
    - commands: List of all available command strings

  ## Returns
    - List of matching command strings
  """
  @spec find_matches(String.t(), [String.t()]) :: [String.t()]
  def find_matches(input, commands) do
    # Score all commands and filter those with acceptable scores
    scored_matches =
      commands
      |> Enum.map(&{&1, score_match(input, &1)})
      |> Enum.filter(fn {_cmd, score} -> score > 0 end)
      |> Enum.sort_by(fn {_cmd, score} -> score end, :desc)

    # Get the best score
    best_score =
      case scored_matches do
        [] -> 0
        [{_cmd, score} | _] -> score
      end

    # Return commands with the best score (or very close to it)
    threshold = best_score * 0.8

    scored_matches
    |> Enum.filter(fn {_cmd, score} -> score >= threshold end)
    |> Enum.map(fn {cmd, _score} -> cmd end)
  end

  @doc """
  Score how well a command matches the input.

  Higher scores indicate better matches.

  ## Parameters
    - input: The user's input
    - command: The command to score against

  ## Returns
    - Float score from 0.0 to 1.0
  """
  @spec score_match(String.t(), String.t()) :: float()
  def score_match(input, command) do
    input = String.downcase(input)
    command_lower = String.downcase(command)

    cond do
      # Exact match (case-insensitive)
      command_lower == input ->
        1.0

      # Command ends with the input (suffix match)
      String.ends_with?(command_lower, "." <> input) ->
        0.95

      # Command contains the input as a segment
      String.contains?(command_lower, "." <> input <> ".") ->
        0.9

      # Partial namespace match (e.g., "agent.create" matches "ll.agent.create")
      partial_namespace_match?(input, command_lower) ->
        0.85

      # Command starts with input
      String.starts_with?(command_lower, input) ->
        0.8

      # Input appears anywhere in command
      String.contains?(command_lower, input) ->
        0.7

      # Check for abbreviation match
      abbreviation_match?(input, command_lower) ->
        0.6

      # Use edit distance for typo correction (if close enough)
      true ->
        edit_distance_score(input, command_lower)
    end
  end

  @doc """
  Check if input matches a partial namespace of the command.

  ## Examples
      iex> partial_namespace_match?("agent.create", "ll.agent.create")
      true

      iex> partial_namespace_match?("world.load", "ll.world.load")
      true
  """
  @spec partial_namespace_match?(String.t(), String.t()) :: boolean()
  def partial_namespace_match?(input, command) do
    # Split both by dots
    input_parts = String.split(input, ".")
    command_parts = String.split(command, ".")

    # Check if input_parts is a suffix of command_parts
    with true <- length(input_parts) < length(command_parts),
         suffix <- Enum.drop(command_parts, length(command_parts) - length(input_parts)) do
      suffix == input_parts
    else
      _ -> false
    end
  end

  @doc """
  Check if input could be an abbreviation of the command.

  ## Examples
      iex> abbreviation_match?("llm.conf", "ll.llm.config")
      true
  """
  @spec abbreviation_match?(String.t(), String.t()) :: boolean()
  def abbreviation_match?(input, command) do
    input_parts = String.split(input, ".")
    command_parts = String.split(command, ".")

    # For dot-separated abbreviations, we need more flexible matching
    # "llm.conf" should match "ll.llm.config" even though "llm" != "ll"
    # We'll check if the input pattern can be found in the command
    cond do
      # If same number of parts, each input part must prefix the corresponding command part
      length(input_parts) == length(command_parts) ->
        input_parts
        |> Enum.zip(command_parts)
        |> Enum.all?(fn {input_part, cmd_part} ->
          String.starts_with?(cmd_part, input_part)
        end)

      # If input has fewer parts, try to find a matching subsequence in command
      length(input_parts) < length(command_parts) ->
        # Try to find where the input pattern could fit in the command
        # For example, "llm.conf" in "ll.llm.config"
        find_abbreviation_match(input_parts, command_parts)

      true ->
        false
    end
  end

  # Helper function to find if input parts can match a subsequence of command parts
  defp find_abbreviation_match(input_parts, command_parts) do
    # Try each possible starting position
    0..(length(command_parts) - length(input_parts))
    |> Enum.any?(fn start_idx ->
      command_slice = Enum.slice(command_parts, start_idx, length(input_parts))

      input_parts
      |> Enum.zip(command_slice)
      |> Enum.all?(fn {input_part, cmd_part} ->
        String.starts_with?(cmd_part, input_part)
      end)
    end)
  end

  @doc """
  Calculate edit distance score between two strings.

  Returns a score from 0.0 to 0.5 based on similarity.
  """
  @spec edit_distance_score(String.t(), String.t()) :: float()
  def edit_distance_score(s1, s2) do
    distance = edit_distance(s1, s2)
    max_len = max(String.length(s1), String.length(s2))

    if distance <= 3 and max_len > 0 do
      # Convert distance to a score (lower distance = higher score)
      similarity = 1.0 - (distance / max_len)
      # Cap at 0.5 for edit distance matches
      min(similarity * 0.5, 0.5)
    else
      0.0
    end
  end

  @doc """
  Calculate Levenshtein edit distance between two strings.
  Uses dynamic programming to avoid exponential complexity.
  """
  @spec edit_distance(String.t(), String.t()) :: non_neg_integer()
  def edit_distance(s1, s2) do
    len1 = String.length(s1)
    len2 = String.length(s2)

    # Early exit for empty strings
    cond do
      len1 == 0 -> len2
      len2 == 0 -> len1
      s1 == s2 -> 0
      true ->
        # Use dynamic programming with a simple list accumulation
        # to avoid the exponential recursion
        chars1 = String.to_charlist(s1)
        chars2 = String.to_charlist(s2)

        # Initialize first row
        prev_row = Enum.to_list(0..len2)

        {_, final_row} =
          chars1
          |> Enum.with_index(1)
          |> Enum.reduce({prev_row, nil}, fn {char1, i}, {prev_row, _} ->
            new_row =
              chars2
              |> Enum.with_index(1)
              |> Enum.reduce([i], fn {char2, j}, acc ->
                cost = if char1 == char2, do: 0, else: 1

                # Get values from previous computations
                prev_val = Enum.at(prev_row, j)
                left_val = hd(acc)
                diag_val = Enum.at(prev_row, j - 1)

                val = min(
                  left_val + 1,           # Deletion
                  min(
                    prev_val + 1,        # Insertion
                    diag_val + cost      # Substitution
                  )
                )

                [val | acc]
              end)
              |> Enum.reverse()

            {new_row, new_row}
          end)

        List.last(final_row)
    end
  end

  @doc """
  Format multiple matches for display to the user.

  ## Parameters
    - matches: List of matching commands

  ## Returns
    - Formatted string for display
  """
  @spec format_multiple_matches([String.t()]) :: String.t()
  def format_multiple_matches(matches) do
    formatted_matches =
      matches
      |> Enum.with_index(1)
      |> Enum.map(fn {cmd, idx} -> "  #{idx}. #{cmd}" end)
      |> Enum.join("\n")

    "? Did you mean:\n#{formatted_matches}"
  end
end