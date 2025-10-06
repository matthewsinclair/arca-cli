# Test mixed .exs and .cli files
# Compute some values that will be used in setup.cli
version_prefix = "arca_cli"
computed_value = String.upcase(version_prefix)

%{
  version_prefix: version_prefix,
  computed_value: computed_value,
  app_name: "Arca CLI"
}
