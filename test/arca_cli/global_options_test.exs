defmodule Arca.Cli.GlobalOptionsTest do
  use ExUnit.Case
  alias Arca.Cli

  describe "merge_style_settings/2" do
    setup do
      # Save and clear environment variables to prevent test pollution
      no_color = System.get_env("NO_COLOR")
      arca_style = System.get_env("ARCA_STYLE")

      System.delete_env("NO_COLOR")
      System.delete_env("ARCA_STYLE")

      on_exit(fn ->
        # Restore original env vars
        if no_color, do: System.put_env("NO_COLOR", no_color), else: System.delete_env("NO_COLOR")

        if arca_style,
          do: System.put_env("ARCA_STYLE", arca_style),
          else: System.delete_env("ARCA_STYLE")
      end)

      :ok
    end

    test "returns settings unchanged when no style options provided" do
      args = %{options: %{}, flags: %{}}
      settings = %{"existing" => "value"}

      result = Cli.merge_style_settings(args, settings)

      assert result == %{"existing" => "value"}
    end

    test "adds style from --cli-style option" do
      args = %{options: %{cli_style: :ansi}, flags: %{}}
      settings = %{}

      result = Cli.merge_style_settings(args, settings)

      assert result == %{"style" => "ansi"}
    end

    test "adds plain style from --cli-no-ansi flag" do
      args = %{options: %{}, flags: %{cli_no_ansi: true}}
      settings = %{}

      result = Cli.merge_style_settings(args, settings)

      assert result == %{"style" => "plain"}
    end

    test "--cli-no-ansi flag overrides --cli-style option" do
      args = %{options: %{cli_style: :ansi}, flags: %{cli_no_ansi: true}}
      settings = %{}

      result = Cli.merge_style_settings(args, settings)

      assert result == %{"style" => "plain"}
    end

    test "CLI options override existing settings" do
      args = %{options: %{cli_style: :dump}, flags: %{}}
      settings = %{"style" => "ansi"}

      result = Cli.merge_style_settings(args, settings)

      assert result == %{"style" => "dump"}
    end
  end

  describe "environment variable support" do
    setup do
      # Save original env vars
      no_color = System.get_env("NO_COLOR")
      arca_style = System.get_env("ARCA_STYLE")

      # Clear env vars before each test
      System.delete_env("NO_COLOR")
      System.delete_env("ARCA_STYLE")

      on_exit(fn ->
        # Restore original env vars
        if no_color, do: System.put_env("NO_COLOR", no_color), else: System.delete_env("NO_COLOR")

        if arca_style,
          do: System.put_env("ARCA_STYLE", arca_style),
          else: System.delete_env("ARCA_STYLE")
      end)

      :ok
    end

    test "NO_COLOR=1 sets style to plain" do
      System.put_env("NO_COLOR", "1")
      args = %{options: %{}, flags: %{}}
      settings = %{}

      result = Cli.merge_style_settings(args, settings)

      assert result == %{"style" => "plain"}
    end

    test "NO_COLOR=true sets style to plain" do
      System.put_env("NO_COLOR", "true")
      args = %{options: %{}, flags: %{}}
      settings = %{}

      result = Cli.merge_style_settings(args, settings)

      assert result == %{"style" => "plain"}
    end

    test "NO_COLOR=0 does not set style" do
      System.put_env("NO_COLOR", "0")
      args = %{options: %{}, flags: %{}}
      settings = %{}

      result = Cli.merge_style_settings(args, settings)

      assert result == %{}
    end

    test "NO_COLOR=false does not set style" do
      System.put_env("NO_COLOR", "false")
      args = %{options: %{}, flags: %{}}
      settings = %{}

      result = Cli.merge_style_settings(args, settings)

      assert result == %{}
    end

    test "ARCA_STYLE sets style when valid" do
      System.put_env("ARCA_STYLE", "ansi")
      args = %{options: %{}, flags: %{}}
      settings = %{}

      result = Cli.merge_style_settings(args, settings)

      assert result == %{"style" => "ansi"}
    end

    test "ARCA_STYLE ignores invalid values" do
      System.put_env("ARCA_STYLE", "invalid")
      args = %{options: %{}, flags: %{}}
      settings = %{}

      result = Cli.merge_style_settings(args, settings)

      assert result == %{}
    end

    test "NO_COLOR takes precedence over ARCA_STYLE" do
      System.put_env("NO_COLOR", "1")
      System.put_env("ARCA_STYLE", "ansi")
      args = %{options: %{}, flags: %{}}
      settings = %{}

      result = Cli.merge_style_settings(args, settings)

      assert result == %{"style" => "plain"}
    end

    test "CLI options override environment variables" do
      System.put_env("NO_COLOR", "1")
      System.put_env("ARCA_STYLE", "plain")
      args = %{options: %{cli_style: :ansi}, flags: %{}}
      settings = %{}

      result = Cli.merge_style_settings(args, settings)

      assert result == %{"style" => "ansi"}
    end

    test "CLI flag overrides environment variables" do
      System.put_env("ARCA_STYLE", "ansi")
      args = %{options: %{}, flags: %{cli_no_ansi: true}}
      settings = %{}

      result = Cli.merge_style_settings(args, settings)

      assert result == %{"style" => "plain"}
    end
  end

  describe "precedence order" do
    setup do
      # Save original env vars
      no_color = System.get_env("NO_COLOR")
      arca_style = System.get_env("ARCA_STYLE")

      System.delete_env("NO_COLOR")
      System.delete_env("ARCA_STYLE")

      on_exit(fn ->
        # Restore original env vars
        System.delete_env("NO_COLOR")
        System.delete_env("ARCA_STYLE")
        if no_color, do: System.put_env("NO_COLOR", no_color)
        if arca_style, do: System.put_env("ARCA_STYLE", arca_style)
      end)

      :ok
    end

    test "full precedence chain: CLI flag > CLI option > env > settings" do
      System.put_env("ARCA_STYLE", "dump")

      # Test each level of precedence

      # 1. Settings only
      args = %{options: %{}, flags: %{}}
      settings = %{"style" => "ansi"}
      result = Cli.merge_style_settings(args, settings)
      assert result["style"] == "dump", "Env should override settings"

      # 2. CLI option overrides env
      args = %{options: %{cli_style: :plain}, flags: %{}}
      result = Cli.merge_style_settings(args, settings)
      assert result["style"] == "plain", "CLI option should override env"

      # 3. CLI flag overrides everything
      args = %{options: %{cli_style: :dump}, flags: %{cli_no_ansi: true}}
      result = Cli.merge_style_settings(args, settings)
      assert result["style"] == "plain", "CLI flag should override all"
    end
  end

  describe "integration with Ctx" do
    test "style from settings flows to Ctx metadata" do
      settings = %{"style" => "plain"}
      ctx = Arca.Cli.Ctx.new(%{}, settings)

      assert ctx.meta == %{style: :plain}
    end

    test "multiple style values work with Ctx" do
      test_cases = [
        {"ansi", :ansi},
        {"json", :json},
        {"plain", :plain},
        {"dump", :dump}
      ]

      for {setting_value, expected_atom} <- test_cases do
        settings = %{"style" => setting_value}
        ctx = Arca.Cli.Ctx.new(%{}, settings)

        assert ctx.meta == %{style: expected_atom},
               "Expected #{setting_value} to become #{expected_atom}"
      end
    end
  end
end
