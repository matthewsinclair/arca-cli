# Clean up the marker file created in setup
marker_file = bindings[:marker_file]

if marker_file && File.exists?(marker_file) do
  File.rm!(marker_file)
end
